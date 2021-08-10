suppressPackageStartupMessages({
    library(scater)
    library(SingleCellExperiment)
    library(TENxPBMCData)
})

fun <- \()
{
    sce <- TENxPBMCData("pbmc68k")
    counts(sce) <- as(counts(sce), "dgCMatrix")
    
    url <- "https://github.com/10XGenomics/single-cell-3prime-paper/raw/master/pbmc68k_analysis/68k_pbmc_barcodes_annotation.tsv"
    fnm <- file.path(tempdir(), "foo.tsv")
    download.file(url, fnm, quiet = TRUE)
    cd <- read.delim(fnm)
    
    rowData(sce)[3] <- NULL
    names(rowData(sce)) <- c("ensembl", "symbol")
    
    old <- c(
        "CD8+ Cytotoxic T",
        "CD8+/CD45RA+ Naive Cytotoxic",
        "CD4+/CD45RO+ Memory",
        "CD19+ B",
        "CD4+/CD25 T Reg",
        "CD56+ NK",
        "CD4+ T Helper2",
        "CD4+/CD45RA+/CD25- Naive T",
        "CD34+",
        "Dendritic",
        "CD14+ Monocyte")
    new <- c(
        "T CD8+",
        "T CD8+",
        "T CD4+",
        "B CD19+",
        "T CD4+",
        "NK CD56+",
        "T CD4+",
        "T CD4+",
        "HSCs CD34+",
        "Dendritic",
        "Monocytes CD14+")
    
    cluster <- new[match(cd$celltype, old)]
    colData(sce) <- DataFrame(cluster)
    
    return(sce)
}