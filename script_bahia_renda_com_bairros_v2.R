# Script alternativo para gerar mapas com tratamento de erro de download
# Tenta contornar problemas de conectividade com GitHub

library(cnefetools)
library(dplyr)
library(geobr)
library(mapview)
library(leafpop)
library(htmlwidgets)

cat("=======================================================\n")
cat("MAPAS DE RENDA POR BAIRRO - BAHIA (VERSÃO ROBUSTA)\n")
cat("=======================================================\n\n")

# Lista dos 11 municípios com bairros
municipios_lista <- list(
  list(code = 2910701, name = "Euclides da Cunha"),
  list(code = 2910800, name = "Feira de Santana"),
  list(code = 2913606, name = "Ilhéus"),
  list(code = 2914802, name = "Itabuna"),
  list(code = 2918407, name = "Juazeiro"),
  list(code = 2919207, name = "Lauro de Freitas"),
  list(code = 2927200, name = "Ruy Barbosa"),
  list(code = 2927408, name = "Salvador"),
  list(code = 2928703, name = "Santo Antônio de Jesus"),
  list(code = 2932705, name = "Uruçuca"),
  list(code = 2933307, name = "Vitória da Conquista")
)

# Função auxiliar para tentar download com retry
tentar_interpolacao <- function(code_muni, name_muni, max_tentativas = 3) {
  for (tentativa in 1:max_tentativas) {
    tryCatch({
      cat(sprintf("    Tentativa %d/%d de interpolação...\n", tentativa, max_tentativas))
      
      # Ler bairros do município
      bairros_muni <- read_neighborhood(year = 2022, simplified = FALSE) |>
        filter(code_muni == !!code_muni)
      
      # Tentar interpolação
      bairros_int <- tracts_to_polygon(
        code_muni = code_muni,
        polygon = bairros_muni,
        vars = c('pop_ph', 'avg_inc_resp'),
        verbose = FALSE
      )
      
      return(bairros_int)
    }, error = function(e) {
      if (tentativa < max_tentativas) {
        cat(sprintf("    ⚠️ Erro na tentativa %d: %s\n", tentativa, e$message))
        cat(sprintf("    Aguardando 10 segundos antes de tentar novamente...\n"))
        Sys.sleep(10)
      }
    })
  }
  
  # Se chegou aqui, todas as tentativas falharam
  return(NULL)
}

# Função para criar popup
criar_popup_renda_bairro <- function(data) {
  popup_html <- sprintf(
    "<b>Bairro:</b> %s<br/>
     <b>Renda Média (R$):</b> %s<br/>
     <b>População:</b> %s pessoas<br/>
     <hr>
     <small>Município: %s</small>",
    data$name_neighborhood,
    format(round(data$avg_inc_resp), big.mark = ".", decimal.mark = ","),
    format(round(data$pop_ph), big.mark = ".", decimal.mark = ","),
    data$name_muni
  )
  return(popup_html)
}

# Criar pasta se não existir
if (!dir.exists("docs/mapas/com_bairros")) {
  dir.create("docs/mapas/com_bairros", recursive = TRUE)
}

cat("Processando municípios com retry automático...\n\n")

resultados <- data.frame(
  municipio = character(),
  sucesso = logical(),
  motivo_erro = character(),
  stringsAsFactors = FALSE
)

# Processar cada município
for (muni_info in municipios_lista) {
  code <- muni_info$code
  name <- muni_info$name
  
  cat(sprintf("--- Processando: %s ---\n", name))
  
  # Tentar interpolação com retry
  bairros_int <- tentar_interpolacao(code, name, max_tentativas = 3)
  
  if (!is.null(bairros_int)) {
    # Filtrar dados válidos
    bairros_int <- bairros_int |>
      filter(!is.na(avg_inc_resp), !is.na(pop_ph), pop_ph >= 10) |>
      mutate(
        renda_inteira = round(avg_inc_resp, 0),
        pop_inteira = round(pop_ph, 0),
        name_muni = name
      )
    
    if (nrow(bairros_int) == 0) {
      cat("  ⚠️ Nenhum bairro com dados válidos\n\n")
      resultados <- rbind(resultados, data.frame(
        municipio = name,
        sucesso = FALSE,
        motivo_erro = "Sem dados válidos",
        stringsAsFactors = FALSE
      ))
      next
    }
    
    cat(sprintf("  Bairros com dados: %d\n", nrow(bairros_int)))
    cat(sprintf("  Renda média: R$ %.2f\n", mean(bairros_int$avg_inc_resp, na.rm = TRUE)))
    
    # Criar popups
    popups <- sapply(1:nrow(bairros_int), function(i) 
      criar_popup_renda_bairro(bairros_int[i, ]))
    
    # Criar mapa
    mapa_renda <- mapview(
      bairros_int, 
      zcol = 'renda_inteira',
      layer.name = paste("Renda Média (R$) -", name),
      alpha.regions = 0.8,
      popup = popups,
      label = bairros_int$name_neighborhood,
      col.regions = colorRampPalette(c("#440154", "#31688e", "#35b779", "#fde724"))(100)
    )
    
    # Salvar
    nome_arquivo <- iconv(name, to="ASCII//TRANSLIT")
    nome_arquivo <- gsub("[^A-Za-z0-9]", "_", nome_arquivo)
    nome_arquivo <- tolower(nome_arquivo)
    caminho_arquivo <- sprintf("docs/mapas/com_bairros/%s.html", nome_arquivo)
    
    htmlwidgets::saveWidget(
      mapa_renda@map, 
      file = caminho_arquivo, 
      selfcontained = FALSE,
      title = paste("Renda por Bairro -", name)
    )
    
    cat(sprintf("  ✓ Mapa salvo com sucesso\n\n"))
    
    resultados <- rbind(resultados, data.frame(
      municipio = name,
      sucesso = TRUE,
      motivo_erro = "",
      stringsAsFactors = FALSE
    ))
  } else {
    cat("  ✗ Falha após 3 tentativas\n\n")
    resultados <- rbind(resultados, data.frame(
      municipio = name,
      sucesso = FALSE,
      motivo_erro = "Falha ao baixar dados (GitHub/IBGE)",
      stringsAsFactors = FALSE
    ))
  }
}

# Relatório final
cat("=======================================================\n")
cat("RELATÓRIO FINAL\n")
cat("=======================================================\n\n")

cat(sprintf("Total de municípios processados: %d\n", nrow(resultados)))
cat(sprintf("Mapas criados com sucesso: %d\n", sum(resultados$sucesso)))
cat(sprintf("Municípios com erro: %d\n\n", sum(!resultados$sucesso)))

if (sum(!resultados$sucesso) > 0) {
  cat("Municípios que falharam:\n")
  for (i in which(!resultados$sucesso)) {
    cat(sprintf("  - %s: %s\n", resultados$municipio[i], resultados$motivo_erro[i]))
  }
  cat("\n")
}

cat("=======================================================\n")
cat("DICAS PARA RESOLVER ERROS DE DOWNLOAD\n")
cat("=======================================================\n\n")

cat("Se você receber erro 'Failed to download sc_29.parquet':\n\n")
cat("1. Verifique sua conexão com a internet\n")
cat("2. Tente novamente em alguns minutos (servidor pode estar ocupado)\n")
cat("3. Reinstale o cnefetools:\n")
cat("   remotes::install_github('ipeaGIT/cnefetools', force = TRUE)\n\n")
cat("4. Se está atrás de firewall corporativo, configure proxy:\n")
cat("   Sys.setenv(http_proxy = 'http://seu.proxy:porta')\n\n")

cat("=======================================================\n")
