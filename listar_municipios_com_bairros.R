# Script auxiliar para listar municípios da Bahia com bairros
# Este script apenas lista os municípios, sem gerar mapas
# Use para saber quais municípios incluir no index.html

library(geobr)
library(dplyr)

cat("=======================================================\n")
cat("MUNICÍPIOS DA BAHIA COM BAIRROS CADASTRADOS NO IBGE\n")
cat("=======================================================\n\n")

cat("Carregando dados dos bairros da Bahia...\n")

# Ler todos os bairros do Brasil e filtrar os da Bahia
bairros_ba <- read_neighborhood(year = 2022, simplified = FALSE)

# Filtrar apenas municípios da Bahia (código inicia com 29)
bairros_ba <- bairros_ba |>
  filter(substr(code_muni, 1, 2) == "29")

# Extrair lista de municípios únicos
municipios_com_bairros <- bairros_ba |>
  as.data.frame() |>
  select(code_muni, name_muni) |>
  distinct() |>
  arrange(name_muni) |>
  mutate(
    # Criar nome de arquivo seguro (remover acentos e substituir espaços)
    arquivo = iconv(name_muni, to="ASCII//TRANSLIT"),
    arquivo = tolower(gsub("[^A-Za-z0-9]", "_", arquivo))
  )

cat("\n--- LISTA DE MUNICÍPIOS ---\n\n")
print(municipios_com_bairros)

cat(sprintf("\n\nTotal: %d municípios\n\n", nrow(municipios_com_bairros)))

# Gerar código JavaScript para o index.html
cat("=======================================================\n")
cat("CÓDIGO PARA COPIAR NO index.html\n")
cat("=======================================================\n\n")
cat("const municipiosComBairros = [\n")

for (i in 1:nrow(municipios_com_bairros)) {
  muni <- municipios_com_bairros[i, ]
  cat(sprintf('  { nome: "%s", arquivo: "%s" }', muni$name_muni, muni$arquivo))
  
  if (i < nrow(municipios_com_bairros)) {
    cat(",\n")
  } else {
    cat("\n")
  }
}

cat("];\n\n")

cat("=======================================================\n")
cat("COPIE O CÓDIGO ACIMA E COLE NO index.html\n")
cat("Na seção: const municipiosComBairros = [...]\n")
cat("=======================================================\n")

# Salvar em arquivo CSV para referência
tryCatch({
  write.csv(municipios_com_bairros, "municipios_com_bairros.csv", row.names = FALSE)
  cat("\nLista também salva em: municipios_com_bairros.csv\n")
}, error = function(e) {
  cat("\nAtenção: Não foi possível salvar o arquivo CSV\n")
  cat("(arquivo pode estar aberto ou sem permissão de escrita)\n")
})
