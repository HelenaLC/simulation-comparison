suppressPackageStartupMessages({
    library(gamlss)
    library(gamlss.tr)
    library(SingleCellExperiment)
    library(zingeR)
})

fun <- function(x) {
    
    x <- readRDS("data/02-sub/Kang18,B_cells.rds")
    
    y <- counts(x)
    if (!is.matrix(x))
        y <- as.matrix(y)
    
    # there's a bug in zingeR::NBsimSingleCell() that will not allow genes 
    # with 0% of zeroes, i.e. genes that are expressed across all cells;
    # see https://github.com/statOmics/zingeR/blob/c789ae53b6e91d15ee6be3cc8b01d5c7c4055721/R/simulation.R#L191
    i <- rowMeans(y == 0) != 0
    x <- x[i, ]; y <- y[i, ]

    g <- factor(sample(2, ncol(x), TRUE))
    mm <- model.matrix(~g)

    p <- getDatasetZTNB(
        counts = y,
        design = mm)

    x <- list(
        dataset = y,
        group = g,
        nTags = nrow(x),
        nlibs = ncol(x),
        pUp = 0,
        verbose = FALSE,
        params = p)
}
