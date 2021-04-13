suppressPackageStartupMessages({
  library(ESCO)
  library(SingleCellExperiment)
})

fun <- function(x) {
  type <- ifelse(x$type == "single", "single", "group")
  y <- escoSimulate(x$params, type, verbose = FALSE, numCores = 1)
  assays(y) <- list(counts = assay(y, "observedcounts"))
  if (type == "group") {
    groups <- factor(y$Group, labels = x$groups)
    cd <- DataFrame(groups)
    names(cd) <- x$type
    colData(y) <- cd
  } else {
    colData(y) <- NULL
  }
  return(y)
}
