suppressPackageStartupMessages({
    library(ExperimentHub)
    library(SingleCellExperiment)
    library(Seurat)
})

fun <- \()
{
    eh <- ExperimentHub()
    q <- query(eh, "SimBenchData")
    
    x <- lapply(
        grep("^Neural", q$title),
        function(i) {
            so <- eh[[q$ah_id[i]]]
            sce <- as.SingleCellExperiment(so)
            # keep 1st experiment only
            sce[, sce$ident == "Cortex1"]
        })
    
    x <- do.call(cbind, x)
    
    colData(x) <- DataFrame(
        batch = x$technology,
        cluster = x$celltype)
    
    assays(x) <- list(counts = counts(x))
    
    return(x)
}