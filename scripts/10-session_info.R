suppressPackageStartupMessages({
    library(emdist)
    library(ESCO)
    library(ExperimentHub) #
    library(jsonlite)
    library(muscat)
    library(Peacock.test)
    #library(POWSC)
    library(powsimR)
})

writeLines(capture.output(sessionInfo()), args[[1]])

# pkgs <- c(
#     "emdist", "JINJINT/ESCO", 
#     "dplyr", 
#     "jsonlite",
#     "Peacock.test", "suke18/POWSC", "purrr", "bvieth/powsimR",
# 
# install.packages("BiocManager")
# BiocManager::install(pkgs, ask = FALSE, dependencies = TRUE)
# 
# install.packages("devtools")
# devtools::install_gitlab("sysbiobig/sparsim")