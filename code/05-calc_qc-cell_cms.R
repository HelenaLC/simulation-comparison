suppressPackageStartupMessages({
    library(CellMixS)
    library(scater)
    library(scran)
    library(SingleCellExperiment)
})

ppFUN <- function(sce) {
    if ("normcounts" %in% assayNames(sce)) {
        logcounts(sce) <- log(normcounts(sce)+1)
    } else sce <- logNormCounts(sce)
    stats <- modelGeneVar(sce)
    hvgs <- getTopHVGs(stats, n = 500)
    sce <- runPCA(sce, subset_row = hvgs)
}

qcFUN <- function(sce) {
    i <- c("batch", "cluster")
    i <- intersect(i, names(colData(sce)))
    if (length(i) == 0) return(NULL)
    ids <- factor(sce[[i]])
    n <- tabulate(ids)
    k <- min(n[n != 0])/2
    cms(sce, k, i)$cms
}

groups <- "global"
n_genes <- NULL
n_cells <- NULL