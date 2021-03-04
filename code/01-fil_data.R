suppressPackageStartupMessages({
    library(Matrix)
    library(SingleCellExperiment)
})

# read in raw data
x <- readRDS(args$raw)

# filter out instances with less than 50 cells
by <- c("cluster", "sample", "batch")
by <- intersect(by, names(colData(x)))

cs <- split(seq(ncol(x)), colData(x)[by])
rmv <- vapply(cs, length, numeric(1)) < 50
if (any(rmv)) x <- x[, -unlist(cs[rmv])]

# keep genes with count > 1 in at least 10 cells,
# and cells with at least 100 detected genes
x <- x[
    rowSums(counts(x) > 1) >= 10,
    colSums(counts(x) > 0) >= 100]

# drop missing factor levels
for (. in by) x[[.]] <- droplevels(factor(x[[.]]))

# save filtered data to .rds
saveRDS(x, args$fil)