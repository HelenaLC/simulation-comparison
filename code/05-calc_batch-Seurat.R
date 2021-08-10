suppressPackageStartupMessages({
    library(scater)
    library(Seurat)
})

fun <- \(x) 
{
    x <- logNormCounts(x)
    k <- min(table(x$batch)/2)
    
    l <- SplitObject(
        as.Seurat(x), 
        split.by = "batch")
    l <- lapply(l, \(.) {
        . <- NormalizeData(., verbose = FALSE)
        . <- FindVariableFeatures(., 
            verbose = FALSE,
            nfeatures = 1000,
            selection.method = "vst")
    })
    fs <- SelectIntegrationFeatures(l)
    as <- FindIntegrationAnchors(l, 
        k.filter = k,
        dims = seq(20), 
        verbose = FALSE,
        anchor.features = fs)
    y <- IntegrateData(as, 
        k.weight = k, 
        verbose = FALSE,
        features.to.integrate = rownames(x))
    
    list(
        assay_in = logcounts(x),
        assay_out = GetAssayData(y))
}