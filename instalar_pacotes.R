# Script para instalar todos os pacotes necessários
# Execute este script antes de gerar os mapas

cat("=======================================================\n")
cat("INSTALANDO PACOTES NECESSÁRIOS PARA OS MAPAS\n")
cat("=======================================================\n\n")

# Lista de pacotes necessários
pacotes <- c(
  "dplyr",
  "geobr",
  "mapview",
  "leafpop",
  "htmlwidgets",
  "sf"
)

cat("Pacotes a serem instalados:\n")
print(pacotes)
cat("\n")

# Instalar pacotes que ainda não estão instalados
for (pacote in pacotes) {
  if (!require(pacote, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("Instalando %s...\n", pacote))
    install.packages(pacote, repos = "https://cloud.r-project.org/", dependencies = TRUE)
  } else {
    cat(sprintf("✓ %s já está instalado\n", pacote))
  }
}

cat("\n=======================================================\n")
cat("Verificando instalação do cnefetools...\n")
cat("=======================================================\n\n")

# Instalar cnefetools do GitHub (se necessário)
if (!require("cnefetools", quietly = TRUE)) {
  cat("Instalando remotes...\n")
  if (!require("remotes", quietly = TRUE)) {
    install.packages("remotes", repos = "https://cloud.r-project.org/")
  }
  
  cat("Instalando cnefetools do GitHub...\n")
  remotes::install_github("ipeaGIT/cnefetools")
} else {
  cat("✓ cnefetools já está instalado\n")
}

cat("\n=======================================================\n")
cat("VERIFICAÇÃO FINAL\n")
cat("=======================================================\n\n")

# Verificar se todos os pacotes foram instalados
todos_ok <- TRUE
for (pacote in c(pacotes, "cnefetools")) {
  if (require(pacote, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("✓ %s: OK\n", pacote))
  } else {
    cat(sprintf("✗ %s: FALHOU\n", pacote))
    todos_ok <- FALSE
  }
}

cat("\n")
if (todos_ok) {
  cat("=======================================================\n")
  cat("✓ TODOS OS PACOTES INSTALADOS COM SUCESSO!\n")
  cat("=======================================================\n")
  cat("\nVocê já pode executar os scripts de geração de mapas.\n")
} else {
  cat("=======================================================\n")
  cat("✗ ALGUNS PACOTES FALHARAM NA INSTALAÇÃO\n")
  cat("=======================================================\n")
  cat("\nVerifique os erros acima e tente instalar manualmente.\n")
}
