# Regera os mapas HTML ja existentes trocando a escala de cores linear
# (minimo -> maximo) por quebras em QUANTIS, calculadas mapa a mapa.
#
# Motivo: a renda por setor/bairro e muito assimetrica. Uns poucos setores de
# renda alta esticam a rampa linear e jogam a grande maioria das areas na mesma
# cor escura (em Guanambi, 97% dos setores ficavam no primeiro quarto da rampa).
# Com quantis, cada classe tem o mesmo numero de areas e o contraste interno de
# cada municipio aparece.
#
# Nao refaz a interpolacao: le os dados direto dos arquivos .fgb que ja estao
# em docs/mapas/**/, recalcula as cores e regrava o HTML no mesmo lugar.
#
# Uso:
#   Rscript regerar_escala_quantis.R                  # todos os mapas, no lugar
#   Rscript regerar_escala_quantis.R guanambi         # so os que casam com o texto
#   Rscript regerar_escala_quantis.R "" C:/saida      # grava em outra pasta
#
# O segundo argumento existe para ambientes em que o R nao tem permissao de
# escrita dentro do repositorio: os mapas saem em <saida>/sem_bairros/ e
# <saida>/com_bairros/ e depois e so copiar por cima de docs/mapas/.

suppressMessages({
  library(sf)
  library(mapview)
  library(htmlwidgets)
  library(jsonlite)
})

source("faixas_renda.R")

# fgb = TRUE mantem a mesma arquitetura dos mapas originais: a geometria vai
# para um arquivo .fgb ao lado do HTML, em vez de embutida como addPolygons.
mapviewOptions(fgb = TRUE)

# Mapas-base sem chave de API; o primeiro da lista e o que abre por padrao.
# Nos mapas por setor censitario o padrao e o OpenStreetMap: os setores sao
# pequenos e os nomes de rua ajudam a localizar cada um no terreno. Nos mapas
# por bairro fica o fundo cinza claro, que nao compete com as areas grandes.
basemaps_do_grupo <- function(grupo) {
  if (identical(grupo, "com_bairros")) {
    c("Esri.WorldGrayCanvas", "Esri.WorldStreetMap", "OpenStreetMap",
      "Esri.WorldImagery", "OpenTopoMap")
  } else {
    c("OpenStreetMap", "Esri.WorldGrayCanvas", "Esri.WorldStreetMap",
      "Esri.WorldImagery", "OpenTopoMap")
  }
}

# A paleta precisa ter exatamente uma cor por classe: com uma rampa de 100 cores
# e 8 quebras o mapview usa so o comeco da rampa em alguns mapas (Feira de
# Santana parava no verde-azulado enquanto Guanambi chegava ao amarelo).
RAMPA <- colorRampPalette(c("#440154", "#31688e", "#35b779", "#fde724"))
N_CLASSES <- 8

# ---------------------------------------------------------------- utilitarios

# Busca sempre por texto literal: um regex com classe negada ([^"]+) nao aguenta
# os HTML maiores (o de Salvador tem 1,2 MB numa unica linha) e volta sem casar.
# Atencao: substring() corta em 1.000.000 de caracteres por padrao (last), o que
# tambem engolia o fim desses arquivos - dai o `last` explicito em toda chamada.
resto_a_partir_de <- function(txt, pos) substring(txt, pos, nchar(txt))

extrair_entre <- function(txt, marca_ini, marca_fim) {
  i <- regexpr(marca_ini, txt, fixed = TRUE)
  if (i == -1) return(NA_character_)
  resto <- resto_a_partir_de(txt, as.integer(i) + nchar(marca_ini))
  fim <- regexpr(marca_fim, resto, fixed = TRUE)
  if (fim == -1) return(NA_character_)
  substring(resto, 1, fim - 1)
}

# A regra de faixas vive em faixas_renda.R, compartilhada com os scripts de
# geracao: quantis arredondados e ultima faixa aberta no p95.

processar_mapa <- function(caminho_html, dir_saida = NULL) {
  nome <- basename(caminho_html)
  cat(sprintf("--- %s\n", nome))

  pasta <- dirname(caminho_html)
  destino <- if (is.null(dir_saida)) pasta else file.path(dir_saida, basename(pasta))
  dir.create(destino, recursive = TRUE, showWarnings = FALSE)
  slug <- sub("[.]html$", "", nome)

  txt <- paste(readLines(caminho_html, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  # A pasta de dependencias e <slug>_lib (sem_bairros) ou <slug>_files
  # (com_bairros). Ha pastas obsoletas das duas formas convivendo no repositorio,
  # entao vale a que o proprio HTML referencia.
  refs <- regmatches(txt, gregexpr(paste0(slug, "_[A-Za-z]+/"), txt))[[1]]
  if (length(refs) == 0) {
    cat("  x pasta de dependencias nao referenciada no HTML\n")
    return(FALSE)
  }
  libdir <- file.path(pasta, sub("/$", "", refs[1]))
  if (!dir.exists(libdir)) {
    cat(sprintf("  x pasta %s nao existe\n", basename(libdir)))
    return(FALSE)
  }

  fgb <- list.files(libdir, pattern = "fgb$", recursive = TRUE, full.names = TRUE)
  if (length(fgb) == 0) {
    cat("  x arquivo .fgb nao encontrado\n")
    return(FALSE)
  }

  titulo <- extrair_entre(txt, "<title>", "</title>")
  # o atributo data-for tem um id variavel: entra pela abertura da tag e
  # descarta o que sobra ate o primeiro ">"
  json <- extrair_entre(txt, '<script type="application/json" data-for=', "</script>")
  if (!is.na(json)) json <- resto_a_partir_de(json, regexpr(">", json, fixed = TRUE) + 1)
  if (is.na(json)) {
    cat("  x JSON do widget nao encontrado\n")
    return(FALSE)
  }

  widget <- fromJSON(json, simplifyVector = FALSE)
  chamada <- NULL
  for (ch in widget$x$calls) if (identical(ch$method, "addFlatGeoBuf")) chamada <- ch
  if (is.null(chamada)) {
    cat("  x camada addFlatGeoBuf nao encontrada\n")
    return(FALSE)
  }

  # reaproveita o nome da camada, os popups e os rotulos ja gerados
  nome_camada <- chamada$args[[2]]
  popups <- unlist(chamada$args[[4]])
  rotulos <- unlist(chamada$args[[5]])

  # dados: mvFeatureId preserva a ordem original, a mesma dos popups
  x <- st_read(fgb[1], quiet = TRUE)
  x <- x[order(x$mvFeatureId), ]
  st_crs(x) <- 4326              # o .fgb vem sem CRS declarado; e lon/lat
  x$fillColor <- NULL            # cores antigas: serao recalculadas
  x$mvFeatureId <- NULL

  if (!is.null(popups) && length(popups) != nrow(x)) {
    cat(sprintf("  x popups (%d) nao batem com as feicoes (%d)\n", length(popups), nrow(x)))
    return(FALSE)
  }
  if (length(rotulos) > 1 && length(rotulos) != nrow(x)) rotulos <- rotulos[1]

  mapviewOptions(basemaps = basemaps_do_grupo(basename(pasta)))

  brk <- quebras_renda(x$renda_inteira)
  faixas <- rotulos_faixas(brk)
  cat(sprintf("  %d feicoes | renda %s a %s | %d faixas | ultima: %s\n",
              nrow(x),
              formatar_reais(min(x$renda_inteira)),
              formatar_reais(max(x$renda_inteira)),
              length(brk) - 1,
              faixas[length(faixas)]))

  mapa <- mapview(
    x,
    zcol = "renda_inteira",
    layer.name = nome_camada,
    alpha.regions = 0.55,
    popup = popups,
    label = rotulos,
    col.regions = RAMPA(length(brk) - 1),
    at = brk
  )
  mapa <- aplicar_rotulos(mapa, brk)

  # saveWidget resolve libdir em relacao ao arquivo: trabalhar dentro da pasta
  wd <- getwd()
  on.exit(setwd(wd), add = TRUE)
  setwd(destino)
  unlink(basename(libdir), recursive = TRUE, force = TRUE)
  saveWidget(
    mapa@map,
    file = nome,
    selfcontained = FALSE,
    libdir = basename(libdir),
    title = titulo
  )
  setwd(wd)

  cat("  ok\n")
  TRUE
}

# --------------------------------------------------------------------- execucao

args <- commandArgs(trailingOnly = TRUE)
filtro <- if (length(args) > 0) args[1] else ""
dir_saida <- if (length(args) > 1 && nzchar(args[2])) args[2] else NULL

mapas <- c(
  list.files("docs/mapas/sem_bairros", pattern = "html$", full.names = TRUE),
  list.files("docs/mapas/com_bairros", pattern = "html$", full.names = TRUE)
)
if (nzchar(filtro)) mapas <- mapas[grepl(filtro, mapas, fixed = TRUE)]

cat(sprintf("Regerando %d mapa(s) com escala em quantis\n", length(mapas)))
cat(sprintf("Saida: %s\n\n", if (is.null(dir_saida)) "no proprio docs/mapas/" else dir_saida))

ok <- vapply(mapas, function(m) isTRUE(processar_mapa(m, dir_saida)), logical(1))

cat(sprintf("\nConcluido: %d de %d mapas regerados\n", sum(ok), length(ok)))
if (any(!ok)) cat("Falharam:\n", paste(" -", basename(mapas[!ok]), collapse = "\n"), "\n")
