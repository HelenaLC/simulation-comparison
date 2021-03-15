suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(purrr)
  library(dplyr)
})
# setwd("~/Desktop/LabRotation_Robinson/simulation-comparison")
# args <- list(
#     sce = "data/02-sub/CellBench,H1975.rds",
#     con = "config/metrics.json")
# wcs <- list(metric = "gene_frq")

x <- readRDS(args$sce)

qc_func <- function(x){return(rowMeans(counts(x) != 0))}

qc <- .calc_qc_for_splits(x=x, metric_name="gene_frq", FUN=qc_func) 
print(dim(qc))
saveRDS(qc, args$res)
