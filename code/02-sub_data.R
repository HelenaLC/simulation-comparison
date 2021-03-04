set.seed(1)
suppressPackageStartupMessages({
    library(jsonlite)
    library(SingleCellExperiment)
})

# read in reference dataset & subsetting parameters 
x <- readRDS(args$fil)
y <- fromJSON(args$con)
y <- y[[wcs$datset]][[wcs$subset]]

# subset cells according to configuration
for (i in names(y)) {
    if (!i %in% names(colData(x))) 
        next
    x <- x[, x[[i]] %in% y[[i]]]
    x[[i]] <- droplevels(factor(x[[i]]))
    # drop cell metadata variable when 
    # there's only one level remaining
    if (nlevels(x[[i]]) == 1) 
        x[[i]] <- NULL
}

# downsample to at most 'ncells' per instance
if (!is.null(y$ncells)) {
    by <- intersect(
        c("cluster", "sample", "batch"),
        names(colData(x)))
    cs <- lapply(
        split(seq(ncol(x)), colData(x)[by]),
        function(.) {
            n <- as.numeric(y$ncells)
            n <- min(n, length(.))
            sample(., n)
        })
    x <- x[, unlist(cs)]
}

# keep genes with count > 1 in at least 10 cells,
x <- x[rowSums(counts(x) > 1) >= 10, ]

# downsample to at most 1k genes
if (nrow(x) > 1e3)
    x <- x[sample(nrow(x), 1e3), ]

# keep cells with at least 10 detected genes
x <- x[, colSums(counts(x) > 0) >= 10]

# save subsetted data to .rds
saveRDS(x, args$sub)