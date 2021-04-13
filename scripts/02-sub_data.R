set.seed(1)
suppressPackageStartupMessages({
    library(jsonlite)
    library(SingleCellExperiment)
})

# read in reference dataset & subsetting parameters 
x <- readRDS(args[[1]])
y <- fromJSON(args[[2]])
y <- y[[wcs$datset]][[wcs$subset]]

# subset cells according to configuration
for (i in names(y)) {
    if (is.null(x[[i]])) next 
    x <- x[, x[[i]] %in% y[[i]]]
    x[[i]] <- droplevels(factor(x[[i]]))
    # drop cell metadata variable when 
    # there's only one level remaining
    if (nlevels(x[[i]]) == 1) 
        x[[i]] <- NULL
}

# keep cells with at least 100 detected genes
x <- x[, colSums(counts(x) > 0) >= 100]

# downsample to at most 'n_cells' per instance
if (!is.null(y$n_cells)) {
    by <- intersect(
        c("cluster", "sample", "batch"),
        names(colData(x)))
    cs <- lapply(
        split(seq(ncol(x)), colData(x)[by]),
        function(.) {
            n <- as.numeric(y$n_cells)
            n <- min(n, length(.))
            sample(., n)
        })
    x <- x[, unlist(cs)]
}

# keep genes with count > 1 in at least 10 cells
x <- x[rowSums(counts(x) > 1) >= 10, ]

# downsample to at most 'n_genes'
if (!is.null(y$n_genes)) {
    n <- as.numeric(y$n_genes)
    n <- min(n, nrow(x))
    x <- x[sample(nrow(x), n), ]
}

# save subsetted data to .rds
saveRDS(x, args[[3]])