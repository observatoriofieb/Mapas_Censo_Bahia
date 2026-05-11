# 📊 Mapas de Renda da Bahia - Censo 2022

Projeto de visualização interativa da distribuição de renda média nos municípios da Bahia, baseado nos dados do Censo 2022 do IBGE.

## 🗺️ Visualize os Mapas

🌐 **Acesse online:** [https://observatoriofieb.github.io/Mapas_Censo_Bahia/](https://observatoriofieb.github.io/Mapas_Censo_Bahia/)

## 📋 Sobre o Projeto

Este projeto oferece duas formas de visualizar a distribuição de renda nos municípios da Bahia:

### 1. 🏘️ Renda por Bairro
- **O que é:** Mapas de municípios da Bahia que possuem bairros oficialmente cadastrados no IBGE
- **Visualização:** Renda média agregada por bairro
- **Método:** Interpolação dasimétrica dos setores censitários para os limites dos bairros
- **Municípios incluídos:** Todos os municípios baianos com delimitação oficial de bairros

### 2. 🏙️ Renda por Setor Censitário
- **O que é:** Mapas dos 20 maiores municípios da Bahia por população
- **Visualização:** Renda média por setor censitário
- **Método:** Dados diretos dos setores censitários do IBGE
- **Municípios incluídos:**
  1. Salvador
  2. Feira de Santana
  3. Vitória da Conquista
  4. Camaçari
  5. Juazeiro
  6. Itabuna
  7. Lauro de Freitas
  8. Ilhéus
  9. Jequié
  10. Teixeira de Freitas
  11. Barreiras
  12. Alagoinhas
  13. Porto Seguro
  14. Simões Filho
  15. Paulo Afonso
  16. Eunápolis
  17. Santo Antônio de Jesus
  18. Luís Eduardo Magalhães
  19. Valença
  20. Guanambi

## 📂 Estrutura do Projeto

```
Mapas_Censo_Bahia/
├── docs/                                    # Pasta para GitHub Pages
│   ├── index.html                          # Página principal com menu
│   ├── mapas/
│   │   ├── com_bairros/                    # Mapas de municípios com bairros
│   │   │   ├── salvador.html
│   │   │   ├── feira_de_santana.html
│   │   │   └── ...
│   │   └── sem_bairros/                    # Mapas dos 20 maiores municípios
│   │       ├── salvador.html
│   │       ├── feira_de_santana.html
│   │       └── ...
│   └── css/                                # Estilos (futuro)
│   └── js/                                 # Scripts (futuro)
├── script_bahia_renda_com_bairros.R        # Gera mapas com bairros
├── script_bahia_renda_sem_bairros.R        # Gera mapas dos 20 maiores
├── README.md
└── .gitignore
```

## 🚀 Como Gerar os Mapas

### Pré-requisitos

1. **R** (versão 4.0 ou superior)
2. **Pacotes R necessários:**

```r
install.packages(c(
  "cnefetools",
  "dplyr",
  "geobr",
  "mapview",
  "leafpop",
  "htmlwidgets"
))
```

### Executar os Scripts

#### 1. Gerar mapas com bairros:

```r
source("script_bahia_renda_com_bairros.R")
```

Este script irá:
- Identificar automaticamente todos os municípios da Bahia com bairros cadastrados
- Baixar os dados do CNEFE e Censo 2022
- Fazer interpolação dasimétrica para cada município
- Gerar mapas HTML interativos em `docs/mapas/com_bairros/`

⏱️ **Tempo estimado:** 30-60 minutos (depende do número de municípios)

#### 2. Gerar mapas sem bairros (20 maiores):

```r
source("script_bahia_renda_sem_bairros.R")
```

Este script irá:
- Processar os 20 maiores municípios da Bahia
- Baixar setores censitários e dados de renda
- Gerar mapas HTML interativos em `docs/mapas/sem_bairros/`

⏱️ **Tempo estimado:** 20-40 minutos

### Visualizar Localmente

Após gerar os mapas, abra o arquivo `docs/index.html` em um navegador web.

## 🌐 Deploy no GitHub Pages

### 1. Inicializar Repositório Git

```bash
git init
git add .
git commit -m "Initial commit - Mapas de Renda da Bahia"
```

### 2. Criar Repositório no GitHub

1. Crie um novo repositório no GitHub (ex: `Mapas_Censo_Bahia`)
2. **Não** inicialize com README, .gitignore ou licença

### 3. Conectar e Fazer Push

```bash
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/Mapas_Censo_Bahia.git
git push -u origin main
```

### 4. Ativar GitHub Pages

1. Acesse o repositório no GitHub
2. Vá em **Settings** → **Pages**
3. Em **Source**, selecione `main` branch
4. Em **Folder**, selecione `/docs`
5. Clique em **Save**
6. Aguarde alguns minutos

🎉 Seu site estará disponível em: `https://SEU_USUARIO.github.io/Mapas_Censo_Bahia/`

## 🔧 Tecnologias Utilizadas

- **R**: Linguagem de programação estatística
- **cnefetools**: Interpolação dasimétrica com dados do CNEFE
- **geobr**: Download de dados geográficos do Brasil (IBGE)
- **mapview**: Visualização interativa de dados espaciais
- **leaflet**: Biblioteca JavaScript para mapas interativos
- **htmlwidgets**: Exportação de visualizações R para HTML

## 📊 Metodologia

### Interpolação Dasimétrica

Os mapas utilizam **interpolação dasimétrica** através do pacote `cnefetools`:

1. **Dados de entrada:** Setores censitários com informações de renda e população
2. **Pontos de referência:** Endereços do CNEFE (Cadastro Nacional de Endereços)
3. **Processo:** Distribuição ponderada dos dados usando densidade de endereços
4. **Resultado:** Agregação dos dados para bairros ou setores censitários

### Variáveis Utilizadas

- **`pop_ph`**: População em domicílios particulares permanentes
- **`avg_inc_resp`**: Renda média do responsável pelo domicílio (em R$)

### Classificação de Renda

Os mapas classificam a renda em 6 categorias:

- 🟣 **Muito Baixa:** < R$ 1.000
- 🔵 **Baixa:** R$ 1.000 - 2.000
- 🟢 **Média-Baixa:** R$ 2.000 - 3.000
- 🟡 **Média:** R$ 3.000 - 5.000
- 🟠 **Média-Alta:** R$ 5.000 - 10.000
- 🔴 **Alta:** > R$ 10.000

## 🎯 Recursos Interativos dos Mapas

- **🖱️ Hover:** Passe o mouse para ver a classificação de renda
- **👆 Click:** Clique para ver informações detalhadas (renda exata, população, etc.)
- **🔍 Zoom/Pan:** Navegue livremente pelo mapa
- **🗺️ Camadas:** Alterne entre diferentes mapas base (OpenStreetMap, satélite, etc.)

## 📝 Fonte de Dados

- **IBGE** - Instituto Brasileiro de Geografia e Estatística
  - Censo Demográfico 2022
  - Malhas territoriais (municípios, setores, bairros)
- **CNEFE 2022** - Cadastro Nacional de Endereços para Fins Estatísticos

## 📄 Licença

MIT License - Sinta-se livre para usar e modificar para seus próprios projetos.

## 👥 Créditos

- **Projeto base:** [Mapas_Salvador_Cnefetools](https://github.com/observatoriofieb/Mapas_Salvador_Cnefetools)
- **Desenvolvido por:** Observatório FIEB
- **Pacote cnefetools:** [https://github.com/ipeaGIT/cnefetools](https://github.com/ipeaGIT/cnefetools)

## 🤝 Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para:

- Reportar bugs
- Sugerir novos recursos
- Melhorar a documentação
- Adicionar novos municípios ou análises

## 📧 Contato

Para dúvidas ou sugestões, abra uma [issue](https://github.com/observatoriofieb/Mapas_Censo_Bahia/issues) no GitHub.

---

Desenvolvido com ❤️ usando R e mapview
