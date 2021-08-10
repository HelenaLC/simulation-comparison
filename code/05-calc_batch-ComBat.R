suppressPackageStartupMessages({
    library(scater)
    library(sva)
})

fun <- \(x)
{
    y <- normalizeCounts(x, log = TRUE)
    if (!is.matrix(y)) y <- as.matrix(y)
    
    df <- data.frame(t(y))
    mm <- model.matrix(~ 1, df)
    
    sink(tempfile())
    suppressMessages({
        z <- ComBat(
            dat = y, 
            batch = x$batch, 
            mod = mm, 
            par.prior = TRUE, 
            prior.plots = FALSE)
    })
    sink()
    
    list(
        assay_in = y,
        assay_out = z)
}