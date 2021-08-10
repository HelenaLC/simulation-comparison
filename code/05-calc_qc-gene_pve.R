suppressPackageStartupMessages({
  library(BiocParallel)
  library(scater)
  library(SingleCellExperiment)
  library(variancePartition)
})

ppFUN <- function(sce) {
    if ("normcounts" %in% assayNames(sce)) {
        logcounts(sce) <- log(normcounts(sce)+1)
    } else sce <- logNormCounts(sce)
    return(sce)
}

qcFUN <- function(sce) {
    i <- c("batch", "cluster")
    i <- intersect(i, names(colData(sce)))
    if (length(i) == 0) return(NULL)
    y <- logcounts(sce)
    if (!is.matrix(y))
        y <- as.matrix(y)
    y <- y[rowSums(y) != 0, ]    
    f <- as.formula(sprintf("~(1|%s)", i))
    cd <- data.frame(colData(sce)[i])
    pve <- fitExtractVarPartModel(y, f, cd, 
        quiet = TRUE, BPPARAM = SerialParam())
    return(pve[[i]])
}

groups <- "global"
n_genes <- NULL
n_cells <- NULL