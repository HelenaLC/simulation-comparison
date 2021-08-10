suppressPackageStartupMessages({
    library(harmony)
    library(scater)
})

fun <- \(x)
{
    y <- calculatePCA(
        logNormCounts(x), 
        ncomponents = 20)
    
    z <- HarmonyMatrix(
        data_mat = y, 
        meta_data = x$batch, 
        do_pca = FALSE, 
        verbose = FALSE)
    
    list(
        dimred_in = y,
        dimred_out = z)
}