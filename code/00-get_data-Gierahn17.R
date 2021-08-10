suppressPackageStartupMessages({
    library(ExperimentHub)
    library(Seurat)
    library(SingleCellExperiment)
})

fun <- \()
{
    eh <- ExperimentHub()
    q <- query(eh, "SimBenchData")
    i <- grep("HEK", q$title)
    x <- eh[[q$ah_id[i]]]
    
    x <- as.SingleCellExperiment(x)
    assays(x) <- assays(x)["counts"]
    colData(x) <- NULL
    
    return(x)
}