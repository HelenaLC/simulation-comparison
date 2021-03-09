suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(dplyr)
})

# setwd("~/Desktop/LabRotation_Robinson/simulation-comparison")
# args <- list(
#     sce = "data/02-sub/CellBench,H1975.rds",
#     con = "config/metrics.json")
# wcs <- list(metric = "gene_frq")

x <- readRDS(args$sce)
qc <- colMeans(counts(x) != 0)

qc_res <- data.frame(colData(x), qc = qc)

saveRDS(qc_res, args$res)