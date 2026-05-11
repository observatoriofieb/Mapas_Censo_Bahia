# Solução para Erro "Failed to download sc_29.parquet from GitHub release"

## 🔴 O Problema

O script está recebendo o erro:
```
Failed to download sc_29.parquet from GitHub release.
```

Isso significa que o pacote `cnefetools` não conseguiu fazer download do arquivo `sc_29.parquet` (setores censitários da Bahia) do GitHub.

## 🤔 Possíveis Causas

1. **Problema de conectividade com GitHub**
   - Firewall corporativo bloqueando acesso
   - Conexão de internet intermitente
   - GitHub fora do ar ou sobrecarregado

2. **Versão do cnefetools desatualizada**
   - Você pode ter uma versão que não consegue fazer download corretamente

3. **Servidor IBGE/GitHub sobrecarregado**
   - Muitos usuários tentando fazer download ao mesmo tempo

## ✅ Soluções

### Opção 1: Aguardar e Tentar Novamente (Recomendado Primeiro)
O erro pode ser temporário. Espere alguns minutos e tente novamente:
```r
# No terminal R, execute novamente o script:
source("script_bahia_renda_com_bairros.R")
```

### Opção 2: Usar Script com Retry Automático
Criei uma versão melhorada que tenta 3 vezes antes de desistir:
```r
source("script_bahia_renda_com_bairros_v2.R")
```

### Opção 3: Reinstalar o Pacote cnefetools
Às vezes a reinstalação resolve o problema:
```r
# Instalar remotes se necessário
install.packages("remotes")

# Reinstalar cnefetools do GitHub
remotes::install_github("ipeaGIT/cnefetools", force = TRUE)

# Depois tentar novamente:
source("script_bahia_renda_com_bairros.R")
```

### Opção 4: Se Está Atrás de Firewall Corporativo
Configure o proxy do R:
```r
# Substitua pelos dados do seu proxy corporativo
Sys.setenv(http_proxy = "http://seu.proxy:porta:usuario:senha")
Sys.setenv(https_proxy = "http://seu.proxy:porta:usuario:senha")

# Depois tente novamente
source("script_bahia_renda_com_bairros.R")
```

### Opção 5: Tentar em Horário de Menor Tráfego
Os servidores do IBGE e GitHub podem ficar sobrecarregados em horários de pico. Tente:
- Madrugada (entre 2h e 6h da manhã)
- Finais de semana
- Fora de horários comerciais (após 18h)

## 📊 Alternativa: Usar Dados em Cache Local

Se você já baixou os dados uma vez, o `cnefetools` faz cache automático:

**Windows:**
```
C:\Users\SEU_USUARIO\AppData\Local\cnefetools\
```

**Linux/Mac:**
```
~/.cache/cnefetools/
```

Para limpar o cache e forçar novo download:
```r
# Windows
unlink("C:\\Users\\SEU_USUARIO\\AppData\\Local\\cnefetools\\", recursive = TRUE)

# Linux/Mac
unlink("~/.cache/cnefetools/", recursive = TRUE)
```

## 🔍 Diagnosticando o Problema

Execute o script de diagnóstico:
```r
source("diagnosticar_problemas.R")
```

## 📈 Progresso

Enquanto isso, aqui está o que você pode fazer:

1. ✅ **Página principal criada** - [docs/index.html](docs/index.html)
2. ✅ **11 municípios identificados** com bairros cadastrados
3. ✅ **Scripts de mapa criados** - prontos para gerar quando a conexão funcionar
4. ❌ **Mapas não gerados ainda** - aguardando resolução do erro de download

## 💡 Próximos Passos Recomendados

1. Tente a **Opção 1** ou **Opção 2** primeiro
2. Se falhar, tente a **Opção 3** (reinstalar cnefetools)
3. Se ainda falhar, tente a **Opção 5** (horário diferente)
4. Se tiver proxy corporativo, tente a **Opção 4**

## 🆘 Se Nada Funcionar

Se o problema persistir após todas as tentativas:

1. Verifique se sua conexão pode acessar GitHub:
   ```
   https://github.com/ipeaGIT/cnefetools/releases
   ```

2. Verifique se pode acessar dados do IBGE:
   ```
   https://www.ibge.gov.br/
   ```

3. Tente em outro computador/conexão para isolar o problema

4. Abra uma issue no repositório:
   ```
   https://github.com/ipeaGIT/cnefetools/issues
   ```

---

## 📝 Logs dos Erros Atuais

A partir dos erros que você relatou, todos os municípios recebem o mesmo erro:
- **Euclides da Cunha**: Falhu na interpolação
- **Feira de Santana**: Falha na interpolação
- **Ilhéus**: Falha na interpolação
- ... (todos com mesmo erro)

Isso sugere que é um problema **único de conectividade**, não específico de cada município.

**Recomendação**: Tente novamente em 30 minutos ou após reinstalar o cnefetools.

---

Boa sorte! 🍀
