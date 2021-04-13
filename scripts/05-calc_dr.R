suppressPackageStartupMessages({
    library(scater)
    library(scran)
    library(SingleCellExperiment)
})

set.seed(1994)

x <- readRDS(args$sce)
x <- logNormCounts(x)

stats <- modelGeneVar(x)
hvgs <- getTopHVGs(stats, n = 500)

x <- runPCA(x, subset_row = hvgs)
x <- runTSNE(x, dimred = "PCA")

dr <- reducedDim(x, "TSNE")
colnames(dr) <- paste0("TSNE", seq(2))

x$lls <- log(colSums(counts(x))+1)
i <- c("cluster", "batch", "lls")
i <- intersect(names(colData(x)), i)
cd <- colData(x)[i]

df <- data.frame(wcs, cd, dr)
saveRDS(df, args$res)
