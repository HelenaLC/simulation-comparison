suppressPackageStartupMessages({
    library(CellMixS)
    library(SingleCellExperiment)
})

# args <- list(
#     sce = "data/02-sub/panc8,inDrop.ductal.rds",
#     res = "outs/batch_sim-panc8,inDrop.ductal,muscat,Seurat.rds")

sce <- readRDS(args[[1]])
res <- readRDS(args[[2]])

df <- if (!is.null(sce) && !is.null(res)) {
    
    if (!is.factor(sce$batch))
        sce$batch <- factor(sce$batch)
    
    group <- "batch"
    k <- min(table(sce$batch))/2
    
    # x = uncorrected, 
    # y = integrated
    if (!is.null(res$dimred_in) && 
        !is.null(res$dimred_out)) {
        # compute scores io dimension reductions
        dimred_in <- dimred_out <- "foo"
        assay_in <- assay_out <- "logcounts"
        # setup input data
        x <- sce
        reducedDim(x, "foo") <- res$dimred_in
        # setup output data
        y <- sce
        reducedDim(y, "foo") <- res$dimred_out 
    } else if (
        !is.null(res$assay_in) && 
        !is.null(res$assay_out)) {
        # compute scores on integrated assay data
        assay_in <- assay_out <- "foo"
        dimred_in <- dimred_out <- "PCA"
        # setup input data
        x <- sce
        assay(x, "foo", FALSE) <- res$assay_in
        # setup output data
        y <- sce
        assay(y, "foo", FALSE) <- res$assay_out
    }
    # split input data by batch
    idx <- split(seq(ncol(x)), x$batch)
    x <- lapply(idx, \(.) x[, .])
        
    suppressMessages({
        # cell-specific changes in Local Density 
        # Factor (LDF) before vs. after integration
        ldf <- ldfDiff(x, y, group, k, dimred_in, dimred_out, assay_in, assay_out)
        
        # cell-specific mixing scores based on 
        # euclidean distances within integrated data
        cms <- cms(y, k, group, dimred_in, assay_in)
    })
    
    data.frame(wcs,
        row.names = NULL,
        batch = sce$batch,
        ldf = ldf$diff_ldf,
        cms = cms$cms)
}

saveRDS(df, args[[3]])