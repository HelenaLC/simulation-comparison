suppressPackageStartupMessages({
    library(dplyr)
    library(jsonlite)
    library(matrixStats)
    library(purrr)
    library(scater)
    library(SingleCellExperiment)
})

# args <- list(
#     sce = "data/04-sim/Mereu20,CD4T,muscat.rds",
#     con = "config/metrics.json")
# wcs <- list(metric = "gene_frq")

x <- readRDS(args$sce)
if (!is.matrix(z <- counts(x)))
    counts(x) <- as.matrix(z)

cpm <- calculateCPM(x)
assay(x, "cpm") <- cpm

#y <- fromJSON(args$con)[[wcs$metric]]
fun <- eval(parse(text = args$fun))

i <- c("cluster", "sample", "batch")
names(i) <- i <- intersect(i, names(colData(x)))
cs <- c(
    list(global = list(foo = TRUE)), 
    lapply(i, function(.) split(seq(ncol(x)), x[[.]])))

res <- map_depth(cs, 2, function(.) {
    df <- data.frame(
        fun(x[, .]), 
        row.names = NULL)
    names(df) <- wcs$metric
    return(df)
})

res <- map_depth(res, 1, bind_rows, .id = "id")
res <- bind_rows(res, .id = "group")

saveRDS(res, args$res)
