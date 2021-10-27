suppressPackageStartupMessages({
    library(Matrix)
    library(SingleCellExperiment)
})

fun <- \()
{
    url <- "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE120221&format=file"
    fnm <- tempfile(fileext = ".tar")
    download.file(url, fnm, quiet = TRUE)

    # unpack data
    dir <- file.path(dirname(fnm), "GSE120221")
    untar(fnm, exdir = dir)
    
    # split files by sample
    fns <- list.files(dir, full.names = TRUE)
    ss <- strsplit(fns, "_")
    ids <- sapply(ss, .subset, 3) 
    ids <- gsub("\\..*", "", ids)
    fns <- split(fns, ids)
    
    # removes replicated samples
    pat <- "(C|S1|2)|(C|Sk)"
    fns <- fns[!grepl(pat, unique(ids))]
    
    l <- lapply(names(fns), \(.) {
        # read in gene metadata
        rd <- grep("genes", fns[[.]], value = TRUE)
        rd <- read.delim(rd, header = FALSE)
        names(rd) <- c("ensembl", "symbol")
        
        # read in cell metadata
        cd <- grep("barcodes", fns[[.]], value = TRUE)
        cd <- read.delim(cd, header = FALSE)
        names(cd) <- "barcode"
        cd$batch <- .
        
        # read in counts
        y <- grep("matrix", fns[[.]], value = TRUE)
        y <- readMM(y)
        dimnames(y) <- list(
            rd$ensembl,
            cd$barcode)
        
        # construct SCE
        SingleCellExperiment(
            assays = list(counts = y),
            rowData = rd, colData = cd)
    })
    # concatenate samples
    do.call(cbind, l)
}