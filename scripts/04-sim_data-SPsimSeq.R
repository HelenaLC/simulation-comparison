suppressPackageStartupMessages({
    library(SPsimSeq)
    library(SingleCellExperiment)
})

fun <- function(x) {
    if (!is.matrix(y <- counts(x)))
        counts(x) <- as.matrix(y)
    if (is.null(colnames(x)))
        colnames(x) <- seq(ncol(x))
    if (is.null(x$batch)) {
        batch <- rep(1, ncol(x))
        batch.config <- 1
    } else {
        # keep genes detected in at least 10 cells per batch
        i <- split(seq(ncol(x)), x$batch)
        x <- x[rowAlls(vapply(i, function(.) 
            rowSums(counts(x[, .]) > 0) >= 10,
            logical(nrow(x)))), ]
        batch <- as.numeric(x$batch)
        batch.config <- tabulate(x$batch)/ncol(x)
    }
    y <- SPsimSeq(
        s.data = counts(x), 
        n.genes = nrow(x), 
        tot.samples = ncol(x),
        batch = batch, 
        batch.config = batch.config,
        model.zero.prob = TRUE, 
        genewiseCor = TRUE,
        result.format = "SCE", 
        return.details = FALSE,
        verbose = FALSE)
    y <- y[[1]]
    rowData(y) <- NULL
    colData(y) <- colData(x)
    return(y)
}
