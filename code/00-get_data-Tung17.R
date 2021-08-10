suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

fun <- \()
{
    url <- "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE77288&format=file&file=GSE77288%5Freads%2Draw%2Dsingle%2Dper%2Dsample%2Etxt%2Egz"
    tmp <- tempfile(fileext = ".txt.gz")
    download.file(url, destfile = tmp)
    
    y <- read.delim(gzfile(tmp))
    cd <- DataFrame(batch = y$individual)
    
    # simplify gene & cell names
    y <- y[, grep("^ENSG", names(y))]
    y <- t(as.matrix(y))
    
    SingleCellExperiment(
        assays = list(counts = y),
        colData = cd)
}