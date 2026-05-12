# Script para gerar mapas de Renda Média por Setor Censitário
# 20 maiores municípios da Bahia
# Usando o pacote cnefetools e mapview para visualização interativa

library(cnefetools)
library(dplyr)
library(geobr)
library(mapview)
library(leafpop)
library(htmlwidgets)

cat("=======================================================\n")
cat("MAPAS DE RENDA - 20 MAIORES MUNICÍPIOS DA BAHIA\n")
cat("=======================================================\n\n")

# 1. Lista dos 20 maiores municípios da Bahia
municipios_maiores <- data.frame(
  name_muni = c(
    "Salvador",
    "Feira de Santana",
    "Vitória da Conquista",
    "Camaçari",
    "Juazeiro",
    "Itabuna",
    "Lauro de Freitas",
    "Ilhéus",
    "Jequié",
    "Teixeira de Freitas",
    "Barreiras",
    "Alagoinhas",
    "Porto Seguro",
    "Simões Filho",
    "Paulo Afonso",
    "Eunápolis",
    "Santo Antônio de Jesus",
    "Luís Eduardo Magalhães",
    "Valença",
    "Guanambi"
  ),
  stringsAsFactors = FALSE
)

cat("Municípios a processar:\n")
print(municipios_maiores)
cat("\n")

# 2. Obter códigos IBGE dos municípios
cat("Obtendo códigos IBGE...\n")
municipios_maiores$code_muni <- sapply(municipios_maiores$name_muni, function(nome) {
  resultado <- lookup_muni(name_muni = nome)
  if (!is.null(resultado) && nrow(resultado) > 0) {
    # Filtrar por estado Bahia se houver múltiplos resultados
    resultado_ba <- resultado[resultado$abbrev_state == "BA", ]
    if (nrow(resultado_ba) > 0) {
      return(resultado_ba$code_muni[1])
    }
  }
  return(NA)
})

# Remover municípios não encontrados
municipios_maiores <- municipios_maiores |>
  filter(!is.na(code_muni))

cat(sprintf("\nMunicípios encontrados: %d\n\n", nrow(municipios_maiores)))

# 3. Criar pasta para os mapas se não existir
if (!dir.exists("docs")) {
  dir.create("docs")
}
if (!dir.exists("docs/mapas")) {
  dir.create("docs/mapas")
}
if (!dir.exists("docs/mapas/sem_bairros")) {
  dir.create("docs/mapas/sem_bairros")
}

# 4. Garantir cache local do parquet da Bahia (fallback ao piggyback)
obter_caminho_cache_sc_ba <- function() {
  if (.Platform$OS.type == "windows") {
    base_cache <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "cache", "R")
  } else {
    base_cache <- file.path(path.expand("~"), ".cache", "R")
  }
  file.path(base_cache, "cnefetools", "sc_assets", "sc_29.parquet")
}

garantir_parquet_bahia <- function(force = FALSE) {
  destino <- obter_caminho_cache_sc_ba()
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)

  arquivo_valido <- file.exists(destino) && file.info(destino)$size > 10 * 1024 * 1024
  if (!force && arquivo_valido) {
    cat("✓ Cache local sc_29.parquet já disponível\n")
    return(TRUE)
  }

  if (file.exists(destino)) {
    unlink(destino, force = TRUE)
  }

  url_sc_bahia <- "https://github.com/pedreirajr/cnefetools/releases/download/sc-assets-v2/sc_29.parquet"
  cat("Baixando sc_29.parquet direto da release...\n")

  baixou <- FALSE
  try({
    utils::download.file(url_sc_bahia, destino, mode = "wb", method = "libcurl", quiet = FALSE)
    baixou <- TRUE
  }, silent = TRUE)

  if (!baixou && .Platform$OS.type == "windows") {
    try({
      utils::download.file(url_sc_bahia, destino, mode = "wb", method = "wininet", quiet = FALSE)
      baixou <- TRUE
    }, silent = TRUE)
  }

  arquivo_valido <- file.exists(destino) && file.info(destino)$size > 10 * 1024 * 1024
  if (!arquivo_valido) {
    cat("✗ Falha ao baixar sc_29.parquet para cache local\n")
    return(FALSE)
  }

  cat(sprintf("✓ Cache sc_29.parquet pronto: %s\n", destino))
  return(TRUE)
}

cat("Preparando cache local dos setores censitários da Bahia...\n")
garantir_parquet_bahia(force = FALSE)

# 5. Função para criar popup customizado
criar_popup_renda_setor <- function(data) {
  popup_html <- sprintf(
    "<b>Renda Média (R$):</b> %s<br/>
     <b>População:</b> %s pessoas<br/>
     <hr>
     <small>Município: %s</small>",
    format(round(data$avg_inc_resp), big.mark = ".", decimal.mark = ","),
    format(round(data$pop_ph), big.mark = ".", decimal.mark = ","),
    data$name_muni
  )
  return(popup_html)
}

# 6. Função para processar um município
processar_municipio <- function(code_muni, name_muni) {
  cat(sprintf("\n--- Processando: %s ---\n", name_muni))
  
  tryCatch({
    # Ler setores censitários do município
    cat("  Carregando setores censitários...\n")
    setores <- read_census_tract(code_tract = code_muni, year = 2022, simplified = FALSE)
    
    cat(sprintf("  Setores encontrados: %d\n", nrow(setores)))
    
    # Interpolar dados de renda média e população
    cat("  Interpolando dados...\n")
    setores_int <- tryCatch(
      {
        tracts_to_polygon(
          code_muni = code_muni,
          polygon = setores,
          vars = c('pop_ph', 'avg_inc_resp'),
          verbose = FALSE
        )
      },
      error = function(e) {
        if (grepl("Failed to download sc_29\\.parquet", e$message, ignore.case = TRUE)) {
          cat("  ⚠️ Falha no download via cnefetools. Tentando fallback de cache e nova tentativa...\n")
          ok_cache <- garantir_parquet_bahia(force = TRUE)
          if (ok_cache) {
            return(tracts_to_polygon(
              code_muni = code_muni,
              polygon = setores,
              vars = c('pop_ph', 'avg_inc_resp'),
              verbose = FALSE
            ))
          }
        }
        stop(e)
      }
    )
    
    # Filtrar setores com dados válidos
    setores_int <- setores_int |>
      filter(!is.na(avg_inc_resp), !is.na(pop_ph), pop_ph >= 5) |>
      mutate(
        renda_inteira = round(avg_inc_resp, 0),
        pop_inteira = round(pop_ph, 0),
        name_muni = name_muni  # Adicionar nome do município
      )
    
    if (nrow(setores_int) == 0) {
      cat("  ⚠️ Nenhum setor com dados válidos\n")
      return(FALSE)
    }
    
    cat(sprintf("  Setores com dados válidos: %d\n", nrow(setores_int)))
    cat(sprintf("  Renda média: R$ %.2f\n", mean(setores_int$avg_inc_resp, na.rm = TRUE)))
    cat(sprintf("  Renda mínima: R$ %.2f\n", min(setores_int$avg_inc_resp, na.rm = TRUE)))
    cat(sprintf("  Renda máxima: R$ %.2f\n", max(setores_int$avg_inc_resp, na.rm = TRUE)))
    
    # Criar labels simples com renda formatada (para hover)
    setores_int <- setores_int |>
      mutate(
        renda_label = sprintf("Renda: R$ %s", format(round(avg_inc_resp), big.mark = ".", decimal.mark = ",")),
        Renda = sprintf("R$ %s", format(round(avg_inc_resp), big.mark = ".", decimal.mark = ",")),
        Populacao = format(round(pop_ph), big.mark = ".", decimal.mark = ","),
        Municipio = name_muni
      )
    
    # Criar mapa interativo
    mapa_renda <- mapview(
      setores_int, 
      zcol = 'renda_inteira',
      layer.name = "Renda",
      alpha.regions = 0.8,
      popup = c("Renda", "Populacao", "Municipio"),
      label = "renda_label",
      col.regions = colorRampPalette(c("#440154", "#31688e", "#35b779", "#fde724"))(100)
    )
    
    # Salvar mapa como HTML
    # Criar nome de arquivo seguro (sem espaços ou caracteres especiais)
    nome_arquivo <- iconv(name_muni, to="ASCII//TRANSLIT")
    nome_arquivo <- gsub("[^A-Za-z0-9]", "_", nome_arquivo)
    nome_arquivo <- tolower(nome_arquivo)
    caminho_arquivo <- sprintf("docs/mapas/sem_bairros/%s.html", nome_arquivo)
    lib_dir <- sprintf("%s_lib", nome_arquivo)
    titulo_html <- sprintf("Renda por Setor Censitario - %s", iconv(name_muni, to = "ASCII//TRANSLIT"))

    if (dir.exists(file.path("docs/mapas/sem_bairros", lib_dir))) {
      unlink(file.path("docs/mapas/sem_bairros", lib_dir), recursive = TRUE, force = TRUE)
    }
    
    htmlwidgets::saveWidget(
      mapa_renda@map,
      file = caminho_arquivo,
      selfcontained = FALSE,
      libdir = lib_dir,
      title = titulo_html
    )
    
    cat(sprintf("  ✓ Mapa salvo: %s\n", caminho_arquivo))
    
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("  ✗ Erro ao processar %s: %s\n", name_muni, e$message))
    return(FALSE)
  })
}

# 7. Processar todos os municípios
cat("\n=======================================================\n")
cat("INICIANDO PROCESSAMENTO DOS MUNICÍPIOS\n")
cat("=======================================================\n")

resultados <- data.frame(
  municipio = character(),
  sucesso = logical(),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(municipios_maiores)) {
  code <- municipios_maiores$code_muni[i]
  name <- municipios_maiores$name_muni[i]
  
  sucesso <- processar_municipio(code, name)
  
  resultados <- rbind(resultados, data.frame(
    municipio = name,
    sucesso = sucesso,
    stringsAsFactors = FALSE
  ))
}

# 8. Relatório final
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

cat("\nMapas salvos em: docs/mapas/sem_bairros/\n")
cat("=======================================================\n")
