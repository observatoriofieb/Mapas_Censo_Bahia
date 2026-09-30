# Regra unica de faixas de renda para todos os mapas do projeto.
#
# Quantis arredondados para numeros redondos, com a ultima faixa aberta
# ("acima de X") a partir do percentil 95.
#
# Por que assim:
# - quantis puros dao contraste (cada classe com o mesmo numero de areas), mas
#   produzem rotulos feios (1.462 a 1.635) e uma ultima faixa absurda, esticada
#   ate o outlier: em Salvador ia de 6.394 a 61.671, cobrindo R$ 55 mil;
# - faixas de largura fixa dao rotulos bonitos mas devolvem o problema que a
#   escala por quantis resolveu: 62% dos setores de Salvador cairiam na mesma
#   cor;
# - arredondar os quantis e abrir a ultima faixa no p95 resolve os dois lados.
#
# Municipios pequenos ganham menos faixas automaticamente (o numero acompanha a
# quantidade de areas, e quebras que se repetem apos o arredondamento somem).

# Passo "redondo" conforme a magnitude do valor.
.passo_de <- function(v) {
  ifelse(v < 2000, 100, ifelse(v < 5000, 500, ifelse(v < 20000, 1000, 5000)))
}
.arredondar <- function(v) { p <- .passo_de(v); round(v / p) * p }
.piso <- function(v) { p <- .passo_de(v); floor(v / p) * p }

formatar_reais <- function(v) {
  format(round(v), big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

# Vetor de quebras para usar no argumento `at` do mapview.
# O atributo "aberta" diz se a ultima classe deve ser rotulada como "acima de X".
quebras_renda <- function(v, max_classes = 8L) {
  v <- v[is.finite(v)]
  if (length(v) == 0 || diff(range(v)) == 0) {
    b <- c(min(v) - 1, max(v) + 1)
    attr(b, "aberta") <- FALSE
    return(b)
  }

  # Cerca de 3 areas por faixa, entre 3 e 8 faixas: um municipio com 9 bairros
  # nao sustenta 8 classes, mas com 19 ja da para distinguir 6.
  n <- min(max_classes, max(3L, length(v) %/% 3L))
  inicio <- .piso(min(v))
  teto <- .arredondar(as.numeric(quantile(v, 0.95)))

  q <- .arredondar(as.numeric(quantile(v, probs = seq(0, 1, length.out = n + 1))))
  b <- unique(c(inicio, q[2:n]))
  b <- unique(c(b[b > inicio & b < teto], teto))
  b <- unique(c(inicio, b))

  aberta <- max(v) > teto
  if (aberta) b <- c(b, max(v)) else b[length(b)] <- max(v)

  # Classes vazias nao ajudam ninguem a ler o mapa.
  repeat {
    if (length(b) <= 3) break
    cont <- as.integer(table(cut(v, breaks = b, include.lowest = TRUE)))
    vazias <- which(cont == 0)
    if (!length(vazias)) break
    corta <- vazias[1] + 1
    if (corta == length(b)) corta <- length(b) - 1
    b <- b[-corta]
    aberta <- aberta && max(v) > b[length(b) - 1]
  }

  attr(b, "aberta") <- aberta
  b
}

rotulos_faixas <- function(b) {
  n <- length(b) - 1
  aberta <- isTRUE(attr(b, "aberta"))
  vapply(seq_len(n), function(i) {
    if (aberta && i == n) sprintf("acima de %s", formatar_reais(b[i]))
    else sprintf("%s – %s", formatar_reais(b[i]), formatar_reais(b[i + 1]))
  }, character(1))
}

# O mapview monta a legenda com faixas fechadas e separador de milhar ingles.
# Reescreve os rotulos no proprio objeto, antes de salvar o HTML.
aplicar_rotulos <- function(mapa, b) {
  rotulos <- rotulos_faixas(b)
  chamadas <- mapa@map$x$calls
  for (i in seq_along(chamadas)) {
    if (identical(chamadas[[i]]$method, "addLegend")) {
      if (length(chamadas[[i]]$args[[1]]$labels) == length(rotulos)) {
        mapa@map$x$calls[[i]]$args[[1]]$labels <- rotulos
      }
    }
  }
  mapa
}
