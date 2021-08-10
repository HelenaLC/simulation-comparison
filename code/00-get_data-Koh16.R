suppressPackageStartupMessages({
    library(Biobase)
    library(GEOquery)
    library(SingleCellExperiment)
})

fun <- \()
{
    url <- "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSM2257302&format=file&file=GSM2257302%5FAll%5Fsamples%5Fsc%5Ftpm%2Etxt%2Egz"
    fnm <- tempfile(fileext = ".txt.gz")
    download.file(url, fnm, quiet = TRUE)
    
    # read in raw data 
    y <- read.delim(gzfile(fnm), header = TRUE)
    
    # make feature metadata
    rd <- data.frame(
        ensembl = y$geneID, 
        symbol = y$geneSymbol)
    
    ex <- grep("^gene", names(y))
    y <- as.matrix(y[, -ex])
    
    # make cell metadata
    cd <- data.frame(cluster = factor(
        gsub("\\..*$", "", colnames(y)),
        levels = c("H7hESC", "APS", "MPS3", "D2_25somitomere", "DLL1PXM", "LatM", "Earlysomite", "cDM", "Sclerotome"),
        labels = c("hESC", "APS", "MPS", "D2.25 Somitomere", "DLL1+PXM", "LatM", "Somite", "Dermo", "Sclerotome")))
    
    # convert TPM to integers
    y <- matrix(as.integer(y), nrow(y), ncol(y))
    
    # construct 'SingleCellExperiment'
    SingleCellExperiment(
        assays = list(counts = y),
        rowData = rd, colData = cd)
}