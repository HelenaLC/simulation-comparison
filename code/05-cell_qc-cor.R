suppressPackageStartupMessages({
  library(edgeR) 
  library(purrr)
  library(dplyr)
  library(SingleCellExperiment)
})

# setwd("~/Desktop/LabRotation_Robinson/simulation-comparison")
# args <- list(
#     sce = "data/02-sub/CellBench,H1975.rds",
#     res = "results/qc_ref-CellBench,H1975,gene_cor.rds",
#     con = "config/metrics.json")

# wcs <- list(maxNForCorr=20)
# wcs <- list(type = "cell", metric = "frq")
maxNForCorr <- 20
x <- readRDS(args$sce)


## Calculate logCPMs
cpms <- edgeR::cpm(counts(x), prior.count = 2, log = TRUE)
dim(cpms)

## split by group = "cluster","batch", "sample". 
cs <- .split_cells(x)
res <- map_depth(cs, -1, function(c){
              
              subset <- cpms[,c]
              n <- min(ncol(subset), maxNForCorr)
              ## Subsample columns 
              subset <- subset[ ,sample(seq_len(ncol(subset)), n, replace = FALSE) ]
              ## Calculate Spearman correlations
              corrs <- stats::cor(subset, use = "pairwise.complete.obs",
                                  method = "spearman")
              df <- data.frame(
                t(combn(seq_len(n), m=2)), 
                cell_cor= corrs[upper.tri(corrs)]
              )
              
})

res <- .combine_res_of_splits(res)
print(res)
saveRDS(res, args$res)