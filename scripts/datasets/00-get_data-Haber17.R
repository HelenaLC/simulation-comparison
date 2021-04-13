suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

url <- "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE92332&format=file&file=GSE92332%5Fatlas%5FUMIcounts%2Etxt%2Egz"
tmp <- tempfile(fileext = ".txt.gz")
download.file(url, destfile = tmp)
y <- read.delim(gzfile(tmp))

ss <- strsplit(colnames(y), "_")
cd <- DataFrame(cluster = sapply(ss, .subset, 3))

# simplify gene & cell names
y <- as.matrix(y)
dimnames(y) <- list(
    paste0("gene", seq_len(nrow(y))),
    paste0("cell", seq_len(ncol(y))))

sce <- SingleCellExperiment(
    assays = list(counts = y),
    colData = cd)

saveRDS(sce, args[[1]])