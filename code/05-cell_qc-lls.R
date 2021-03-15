

suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(dplyr)
  library(purrr)
})

# setwd("~/Desktop/LabRotation_Robinson/simulation-comparison")
# args <- list(
#     sce = "data/02-sub/CellBench,H1975.rds",
#     con = "config/metrics.json")
# wcs <- list(metric = "gene_frq")

x <- readRDS(args$sce)

qc_func <- function(x){return(log(colSums(counts(x)) + 1))}

qc <- .calc_qc_for_splits(x=x, metric_name="cell_lls", FUN=qc_func) 
print(dim(qc))
saveRDS(qc, args$res)
