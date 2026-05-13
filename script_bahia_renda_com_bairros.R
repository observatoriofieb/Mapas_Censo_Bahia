# Script para gerar mapas de Renda Média por Bairro - Municípios da Bahia
# Para municípios com bairros cadastrados no IBGE
# Usando o pacote cnefetools e mapview para visualização interativa

library(cnefetools)
library(dplyr)
library(geobr)
library(mapview)
library(leafpop)
library(htmlwidgets)

cat("=======================================================\n")
cat("MAPAS DE RENDA POR BAIRRO - MUNICÍPIOS DA BAHIA\n")
cat("=======================================================\n\n")

# 1. Identificar municípios da Bahia que possuem bairros
cat("Carregando bairros da Bahia...\n")
bairros_ba <- read_neighborhood(year = 2022, simplified = FALSE)

# Filtrar apenas municípios da Bahia (código inicia com 29)
bairros_ba <- bairros_ba |>
  filter(substr(code_muni, 1, 2) == "29")

# Ver quais municípios têm bairros
municipios_com_bairros <- bairros_ba |>
  as.data.frame() |>
  select(code_muni, name_muni) |>
  distinct() |>
  arrange(name_muni)

cat("\nMunicípios da Bahia com bairros cadastrados no IBGE:\n")
print(municipios_com_bairros)
cat(sprintf("\nTotal: %d municípios\n\n", nrow(municipios_com_bairros)))

# 2. Criar pasta para os mapas se não existir
if (!dir.exists("docs")) {
  dir.create("docs")
}
if (!dir.exists("docs/mapas")) {
  dir.create("docs/mapas")
}
if (!dir.exists("docs/mapas/com_bairros")) {
  dir.create("docs/mapas/com_bairros")
}

# 3. Função para criar popup customizado
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

# 4. Função para processar um município
processar_municipio <- function(code_muni, name_muni) {
  cat(sprintf("\n--- Processando: %s ---\n", name_muni))
  
  tryCatch({
    # Obter bairros do município
    bairros_muni <- bairros_ba |>
      filter(code_muni == !!code_muni)
    
    cat(sprintf("  Bairros encontrados: %d\n", nrow(bairros_muni)))
    
    # Interpolar dados de renda média e população
    cat("  Interpolando dados...\n")
    bairros_int <- tracts_to_polygon(
      code_muni = code_muni,
      polygon = bairros_muni,
      vars = c('pop_ph', 'avg_inc_resp'),
      verbose = FALSE
    )
    
    # Filtrar bairros com dados válidos
    bairros_int <- bairros_int |>
      filter(!is.na(avg_inc_resp), !is.na(pop_ph), pop_ph >= 10) |>
      mutate(
        renda_inteira = round(avg_inc_resp, 0),
        pop_inteira = round(pop_ph, 0)
      )
    
    if (nrow(bairros_int) == 0) {
      cat("  ⚠️ Nenhum bairro com dados válidos\n")
      return(FALSE)
    }
    
    cat(sprintf("  Bairros com dados válidos: %d\n", nrow(bairros_int)))
    cat(sprintf("  Renda média: R$ %.2f\n", mean(bairros_int$avg_inc_resp, na.rm = TRUE)))
    
    # Criar popups
    popups <- sapply(1:nrow(bairros_int), function(i) 
      criar_popup_renda_bairro(bairros_int[i, ]))
    
    # Criar mapa interativo
    mapa_renda <- mapview(
      bairros_int, 
      zcol = 'renda_inteira',
      layer.name = paste("Renda Média (R$) -", name_muni),
      alpha.regions = 0.8,
      popup = popups,
      label = bairros_int$name_neighborhood,
      col.regions = colorRampPalette(c("#440154", "#31688e", "#35b779", "#fde724"))(100)
    )
    
    # Salvar mapa como HTML
    # Criar nome de arquivo seguro (sem espaços ou caracteres especiais)
    nome_arquivo <- chartr(
      "áàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ",
      "aaaaaaeeeeiiiiooooouuuucAAAAAAAAEEEEIIIIOOOOOUUUUC",
      name_muni
    )
    nome_arquivo <- gsub("[^A-Za-z0-9]", "_", nome_arquivo)
    nome_arquivo <- gsub("_+", "_", nome_arquivo)
    nome_arquivo <- gsub("^_|_$", "", nome_arquivo)
    nome_arquivo <- tolower(nome_arquivo)
    caminho_arquivo <- sprintf("docs/mapas/com_bairros/%s.html", nome_arquivo)
    
    htmlwidgets::saveWidget(
      mapa_renda@map, 
      file = caminho_arquivo, 
      selfcontained = FALSE,
      title = paste("Renda por Bairro -", name_muni)
    )
    
    cat(sprintf("  ✓ Mapa salvo: %s\n", caminho_arquivo))
    
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("  ✗ Erro ao processar %s: %s\n", name_muni, e$message))
    return(FALSE)
  })
}

# 5. Processar todos os municípios
cat("\n=======================================================\n")
cat("INICIANDO PROCESSAMENTO DOS MUNICÍPIOS\n")
cat("=======================================================\n")

resultados <- data.frame(
  municipio = character(),
  sucesso = logical(),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(municipios_com_bairros)) {
  code <- municipios_com_bairros$code_muni[i]
  name <- municipios_com_bairros$name_muni[i]
  
  sucesso <- processar_municipio(code, name)
  
  resultados <- rbind(resultados, data.frame(
    municipio = name,
    sucesso = sucesso,
    stringsAsFactors = FALSE
  ))
}

# 6. Relatório final
cat("\n=======================================================\n")
cat("RELATÓRIO FINAL\n")
cat("=======================================================\n\n")

cat(sprintf("Total de municípios processados: %d\n", nrow(resultados)))
cat(sprintf("Mapas criados com sucesso: %d\n", sum(resultados$sucesso)))
cat(sprintf("Municípios com erro: %d\n\n", sum(!resultados$sucesso)))

if (sum(!resultados$sucesso) > 0) {
  cat("Municípios com erro:\n")
  print(resultados[!resultados$sucesso, ])
}

cat("\nMapas salvos em: docs/mapas/com_bairros/\n")
cat("=======================================================\n")
