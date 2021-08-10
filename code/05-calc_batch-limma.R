suppressPackageStartupMessages({
    library(edgeR)
    library(limma)
})

fun <- \(x)
{
    mm <- model.matrix(~ x$batch) 
    y <- DGEList(counts(x))
    
    y <- calcNormFactors(y, method = "TMMwsp")
    v <- voom(y, mm, plot = FALSE)
    z <- removeBatchEffect(v, x$batch)
    
    list(
        assay_in = v$E,
        assay_out = z) 
}