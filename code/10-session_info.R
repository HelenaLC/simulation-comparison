x <- c(
# GENERAL
# Bioconductor
    "Biobase",
    "BiocParallel",
    "CellBench",
    "ExperimentHub",
    "GEOquery",
    "scater",
    "scran",
    "SingleCellExperiment",
    "TENxPBMCData",
    "variancePartition",
    "waddR",
# CRAN
    "cluster",
    "dplyr",
    "emdist",
    "jsonlite",
    "ggplot2",
    "ggpubr",
    "ggrastr",
    "Matrix",
    "matrixStats",
    "patchwork",
    "Peacock.test",
    "RANN",
    "RColorBrewer",
    "Seurat",
    "SeuratData",
    "tidyr",
    "tidytext",
# SIMULATION
# Bioconductor
    "BASiCS",
    "muscat",
    "scDD",
    "splatter",
    "SPsimSeq",
    "zinbwave",
# GitHub
    "JINJINT/ESCO",
    "suke18/POWSC",
    "bvieth/powsimR",
    "Vivianstats/scDesign",
    "JSB-UCLA/scDesign2",
    "YosefLab/SymSim",
    "statOmics/zingeR",
# INTEGRATION
# Bioconductor
    "batchelor",
    "CellMixS",
    "edgeR",
    "limma",
    "sva",
    # CRAN
    "harmony",
# CLUSTERING
# Bioconductor
    "ConsensusClusterPlus",
    "flowCore",
    "monocle",
    "SC3",
# CRAN
    "clue",
    "Rtsne",
# GitHub
    "VCCRI/cidr",
    "JustinaZ/pcaReduce"
)

# # TO INSTALL ALL DEPENDENCIES:
# if (!require(BiocManager)) 
#     install.packages("BiocManager")
# for (. in x) 
#     if (!require(., character.only = TRUE)) 
#         BiocManager::install(., ask = FALSE, update = TRUE)

# TO CAPTURE SESSIO INFO:
for (. in x) {
    . <- gsub(".*/", "", .)
    suppressPackageStartupMessages(
        library(., character.only = TRUE))
}
si <- capture.output(sessionInfo())
writeLines(si, args[[1]])
