suppressPackageStartupMessages({
    library(mfa)
    library(scater)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    y <- normalizeCounts(y)
    l <- empirical_lambda(t(y))
    list(G = nrow(x), C = ncol(x), lambda = l)
}
