suppressPackageStartupMessages({
    library(gamlss)
    library(gamlss.tr)
    library(SingleCellExperiment)
    library(zingeR)
})

fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(x))
        y <- as.matrix(y)
    g <- factor(sample(2, ncol(y), TRUE))
    mm <- model.matrix(~g)
    p <- getDatasetZTNB(
        counts = y,
        design = mm)
    list(
        dataset = y,
        group = g,
        nTags = p$dataset.nTags,
        nlibs = length(p$dataset.lib.size),
        pUp = 0,
        verbose = FALSE,
        params = p)
}
