fun <- function(x, y)
{
    z <- if (isTRUE(y == "pnorm")) 
        list(mean = mean(x), sd = sd(x))
    suppressWarnings(z <- do.call(ks.test, c(list(x, y), z)))
    as.numeric(1-z$statistic)
}