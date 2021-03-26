suppressPackageStartupMessages({
    library(dplyr)
    library(edgeR)
    library(scater)
    library(Seurat)
    library(splatter)
    library(SingleCellExperiment)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    z <- splatEstimate(y)
    
    i <- c("cluster", "batch")
    i <- intersect(i, names(colData(x)))
    if (length(i) != 0) {
        .fit <- function(y, i) {
            y <- DGEList(y)
            y <- calcNormFactors(y)
            cd <- data.frame(colData(x))
            f <- as.formula(paste("~", i))
            mm <- model.matrix(f, cd)
            y <- estimateDisp(y, mm)
            fit <- glmFit(y)
            bs <- fit$coefficients
            bs <- as.matrix(bs)
        }
        switch(i,
            cluster = {
                bs <- .fit(y, i)
                de.facLoc <- c(0, colMeans(bs[, -1]))
                de.facScale <- colSds(bs)
                group.prob <- prop.table(tabulate(x$cluster))
                
                x <- logNormCounts(x)
                so <- as.Seurat(x)
                Idents(so) <- x$cluster
                mgs <- FindAllMarkers(so, verbose = FALSE)
                
                fil <- filter(mgs,
                    p_val_adj < 0.05,
                    abs(avg_log2FC) > 1) %>% 
                    mutate(dir = sign(avg_log2FC)) %>% 
                    dplyr::count(cluster, dir)
                de.prob <- fil %>% 
                    group_by(cluster) %>% 
                    summarize(n = sum(n)) %>% 
                    pull("n") %>% 
                    prop.table()
                de.downProb <- fil %>% 
                    filter(dir == -1) %>% 
                    pull("n") %>% 
                    prop.table()
                
                z <- setParams(z,
                    de.facLoc = de.facLoc,
                    de.facScale = de.facScale,
                    group.prob = group.prob,
                    de.prob = de.prob,
                    de.downProb = de.downProb)
            },
            batch = {
                bs <- .fit(y, i)
                batch.facLoc <- c(0, colMeans(bs[, -1]))
                batch.facScale <- colSds(bs)
                batchCells <- tabulate(x$batch)
                z <- setParams(z,
                    batchCells = batchCells,
                    batch.facLoc = batch.facLoc,
                    batch.facScale = batch.facScale)
            }
        )
    }
    list(
        params = z,
        ids = list(
            batch = unique(x$batch),
            cluster = unique(x$cluster)))
}