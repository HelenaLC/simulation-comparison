suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

url <- "https://zenodo.org/record/1443566/files/real/gold/myoblast-differentiation_trapnell.rds?download=1"
fnm <- tempfile()
download.file(url, fnm, quiet = TRUE)
dat <- readRDS(fnm)

sce <- SingleCellExperiment(
    assays = list(counts = t(dat$counts)),
    colData = DataFrame(path = factor(dat$grouping)),
    metadata = list(topo = "linear"))

saveRDS(sce, args[[1]])
