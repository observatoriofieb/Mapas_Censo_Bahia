# Script para diagnosticar e resolver problemas com cnefetools
# Este script ajuda a identificar e contornar problemas de download

cat("=======================================================\n")
cat("DIAGNÓSTICO E RESOLUÇÃO DE PROBLEMAS - CNEFETOOLS\n")
cat("=======================================================\n\n")

# 1. Verificar conectividade com GitHub
cat("1. Testando conectividade com GitHub...\n")
tryCatch({
  url_test <- "https://github.com/"
  conexao <- url(url_test)
  on.exit(close(conexao))
  cat("   ✓ Conexão com GitHub OK\n\n")
}, error = function(e) {
  cat("   ✗ Não conseguiu conectar ao GitHub\n")
  cat("   Possíveis causas:\n")
  cat("   - Firewall bloqueando acesso\n")
  cat("   - Conexão de internet instável\n")
  cat("   - GitHub fora do ar\n\n")
})

# 2. Verificar versão do cnefetools
cat("2. Verificando versão do cnefetools...\n")
tryCatch({
  library(cnefetools)
  cat("   ✓ cnefetools carregado com sucesso\n")
  # Tentar descobrir versão
  if (exists("packageVersion")) {
    versao <- packageVersion("cnefetools")
    cat(sprintf("   Versão: %s\n", versao))
  }
  cat("\n")
}, error = function(e) {
  cat("   ✗ Erro ao carregar cnefetools\n")
  cat(sprintf("   Mensagem: %s\n\n", e$message))
})

# 3. Tentar reintalar cnefetools
cat("3. Opções de resolução:\n\n")
cat("Opção A: Reinstalar cnefetools (recomendado)\n")
cat("   Execute no R:\n")
cat("   remotes::install_github('ipeaGIT/cnefetools', force = TRUE)\n\n")

cat("Opção B: Atualizar pacotes relacionados\n")
cat("   Execute no R:\n")
cat("   install.packages(c('geobr', 'sf', 'dplyr'), force = TRUE)\n\n")

cat("Opção C: Verificar problema de firewall/proxy\n")
cat("   Se você está atrás de um proxy corporativo,\n")
cat("   configure o proxy do R:\n")
cat("   Sys.setenv(http_proxy = 'http://seu.proxy:porta')\n\n")

cat("Opção D: Usar cache local se disponível\n")
cat("   O cnefetools faz cache automático em:\n")
if (.Platform$OS.type == "windows") {
  cat_path <- file.path(Sys.getenv("LOCALAPPDATA"), "cnefetools")
} else {
  cat_path <- file.path(Sys.getenv("HOME"), ".cache/cnefetools")
}
cat(sprintf("   %s\n\n", cat_path))

cat("=======================================================\n")
cat("PRÓXIMOS PASSOS\n")
cat("=======================================================\n\n")
cat("1. Escolha uma das opções acima\n")
cat("2. Tente novamente executar os scripts de mapas\n")
cat("3. Se o problema persistir, tente em outro horário\n")
cat("   (os servidores do IBGE/GitHub podem estar sobrecarregados)\n\n")

cat("Aguardando sua ação...\n")
