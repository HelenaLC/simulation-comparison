suppressPackageStartupMessages({
  library(scater)
  library(purrr)
  library(dplyr)
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

qc_func <- function(x){return(rowMeans(log(cpm(x) + 1) ))}

qc <- .calc_qc_for_splits(x=x, metric_name="gene_avg", FUN=qc_func) 
print(dim(qc))
saveRDS(qc, args$res)