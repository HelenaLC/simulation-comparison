suppressPackageStartupMessages({
    library(Seurat)
    library(SingleCellExperiment)
})

fun <- \(x) 
{
    if (is.null(rownames(x))) 
        rownames(x) <- paste0("gene", seq(nrow(x)))
    if (is.null(colnames(x))) 
        colnames(x) <- paste0("cell", seq(ncol(x)))
    
    y <- CreateSeuratObject(
        counts = counts(x), 
        meta.data = colData(x))
    
    y <- NormalizeData(y, verbose = FALSE)
    y <- ScaleData(y, verbose = FALSE) 
    y <- FindVariableFeatures(y, verbose = FALSE) 
    hvgs <- VariableFeatures(y)
    
    y <- RunPCA(y, npcs = n <- 30, features = hvgs, verbose = FALSE) 
    y <- FindNeighbors(y, dims = seq(n), verbose = FALSE) 
    y <- FindClusters(y, res = 0.8, verbose = FALSE) 
    Idents(y)
}
