suppressPackageStartupMessages({
    library(emdist)
    library(ExperimentHub)
    library(dplyr)
    library(jsonlite)
    library(ggplot2)
    library(matrixStats)
    library(patchwork)
    library(Peacock.test)
    library(POWSC)
    library(purrr)
    library(scater)
    library(scran)
    library(SeuratData)
    library(splatter)
    library(SPsimSeq)
    library(SymSim)
    library(tidyr)
})

writeLines(capture.output(sessionInfo()), args[[1]])

# pkgs <- c(
#     "BASiCS",
#     "CellBench",
#     "dyngen", "dplyr",
#     "emdist", "ExperimentHub",
#     "jsonlite",
#     "ggplot2",
#     "matrixStats",
#     "patchwork", "Peacock.test", "suke18/POWSC", "purrr", "bvieth/powsimR",
#     "Vivianstats/scDesign", "JSB-UCLA/scDesign2",
#     "scater", "scran", "Seurat", "satijalab/seurat-data", "splatter", "SPsimSeq", "YosefLab/SymSim",
#     "tidyr", "variancePartition")
# 
# install.packages("BiocManager")
# BiocManager::install(pkgs, ask = FALSE, dependencies = TRUE)
# 
# install.packages("devtools")
# devtools::install_gitlab("sysbiobig/sparsim")