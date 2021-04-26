suppressPackageStartupMessages({
  library(SymSim)
  library(SingleCellExperiment)
})
#type (k)?
fun <- function(x) {
    y <- counts(x)
    if (!is.matrix(y))
        y <- as.matrix(y)
    fn <- "foo.pdf"
    z <- BestMatchParams(
        tech = "UMI",
        counts = y,
        plotfilename = fn,
        n_optimal = 1)
    file.remove(fn)
    z$ngenes <- nrow(x)
    z$ncells_total <- ncol(x)
    n <- length(unique(x$batch))
    z$nbatch <- ifelse(n == 0, 1, n)
    list(params = z, batch = x$batch)
}