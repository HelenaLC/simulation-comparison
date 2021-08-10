fun <- function(x, y) {
    suppressWarnings(z <- ks.test(x, y))
    as.numeric(z$statistic)
}