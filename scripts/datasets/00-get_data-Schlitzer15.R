suppressPackageStartupMessages({
    library(Biobase)
    library(dplyr)
    library(GEOquery)
    library(SingleCellExperiment)
})

url <- "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE60781&format=file"
fnm <- tempfile(fileext = ".tar")
download.file(url, fnm, quiet = TRUE)
untar(fnm, exdir = dirname(fnm))

pat <- ".*read[cC]ount\\.txt\\.gz"
fns <- list.files(dirname(fnm), pat, full.names = TRUE)

y <- lapply(fns, function(.) {
    id <- gsub("_.*", "", basename(.))
    read.delim(gzfile(.), header = FALSE, 
        row.names = 1, col.names = c("gene", id))
}) %>% bind_cols()

ex <- c("no_feature", "ambiguous", "too_low_aQual", "not_aligned", "alignment_not_unique")
y <- y[setdiff(rownames(y), ex), ]

tmp <- tempdir()
geo <- getGEO("GSE60781", destdir = tmp) 
df <- phenoData(geo[[1]])
df <- as(df, "data.frame")
file.remove(tmp, recursive = TRUE)

cd <- DataFrame(
    row.names = df$geo_accession,
    timepoint = gsub("_[0-9]+", "", df$title))
cd <- cd[colnames(y), , drop = FALSE]

sce <- SingleCellExperiment(
    assay = list(counts = y),
    colData = cd)

topo <- data.frame(
    from = c("MDP", "CDP"),
    to = c("CDP", "PreDC"))
metadata(sce)$topology <- topo

saveRDS(sce, args[[1]])
