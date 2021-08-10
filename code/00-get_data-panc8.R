# load required packages
suppressPackageStartupMessages({
    library(Seurat)
    library(SeuratData)
    library(SingleCellExperiment)
})

fun <- \()
{
    if (!require(panc8.SeuratData))
        InstallData("panc8.SeuratData")
    
    # load data as 'Seurat' object
    data("panc8")
    x <- as.SingleCellExperiment(panc8)
    
    # drop log-normalized counts
    # (these are identical to counts)
    assay(x, "logcounts") <- NULL
    
    # exclude datasets with non-integer counts
    x <- x[, !x$tech %in% c("celseq", "celseq2", "fluidigmc1")]
    
    # drop spike-ins
    x <- x[-grep("ERCC", rownames(x)), ]
    
    # drop undetected genes
    x <- x[rowSums(assay(x)) > 0, ]
    
    # subset & rename cell metadata
    colData(x) <- DataFrame(
        batch = x$dataset, 
        cluster = x$celltype)
    
    return(x)
}