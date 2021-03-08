suppressPackageStartupMessages({
  library(scater)
  library(matrixStats)
  library(SingleCellExperiment)
})

# setwd("~/Desktop/LabRotation_Robinson/simulation-comparison")
# args <- list(
#     sce = "data/02-sub/CellBench,H1975.rds",
#     con = "config/metrics.json")
# wcs <- list(metric = "gene_frq")

x <- readRDS(args$sce)
cpm <- calculateCPM(x)
assay(x, "cpm") <- cpm
qc <- matrixStats::rowVars(as.matrix(log(cpm(x) + 1))) 

saveRDS(qc, args$res)