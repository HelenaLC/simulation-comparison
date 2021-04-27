suppressPackageStartupMessages({
    library(emdist)
    library(ESCO)
    library(ExperimentHub)
    library(dreval)
    library(dplyr)
    library(dyngen)
    library(jsonlite)
    library(ggplot2)
    library(ggrastr)
    library(matrixStats)
    library(muscat)
    library(patchwork)
    library(Peacock.test)
    #library(POWSC)
    library(powsimR)
    library(purrr)
    library(scater)
    library(scDD)
    library(scDesign)
    library(scDesign2)
    library(scran)
    library(SeuratData)
    library(splatter)
    library(SPsimSeq)
    library(SymSim)
    library(TENxPBMCData)
    library(tidyr)
    library(variancePartition)
    library(waddR)
})

writeLines(capture.output(sessionInfo()), args[[1]])

# pkgs <- c(
#     "BASiCS",
#     "CellBench",
#     "emdist", "JINJINT/ESCO", "ExperimentHub",
#     "dplyr", "csoneson/dreval","scDD",
#     "jsonlite",
#     "ggplot2", "VPetukhov/ggrastr",
#     "matrixStats",
#     "patchwork", "Peacock.test", "suke18/POWSC", "purrr", "bvieth/powsimR",
#     "Vivianstats/scDesign", "JSB-UCLA/scDesign2", 
#     "scater", "scran", "Seurat", "satijalab/seurat-data", "splatter", "SPsimSeq", "YosefLab/SymSim",
#     "TENxPBMCData", "tidyr", "variancePartition", "waddR")
# 
# install.packages("BiocManager")
# BiocManager::install(pkgs, ask = FALSE, dependencies = TRUE)
# 
# install.packages("devtools")
# devtools::install_gitlab("sysbiobig/sparsim")