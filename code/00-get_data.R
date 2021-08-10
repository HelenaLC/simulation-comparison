# retrieve dataset
source(args[[1]])
x <- fun()

# number of features & observations
dim(x)

# tabulate number of cells by
# batch, cluster, batch-cluster
b <- !is.null(x$batch)
k <- !is.null(x$cluster)
if (b) {
    table(x$batch)
    if (k) {
        table(x$cluster)
        table(x$batch, x$cluster)
    }
} else if (k) {
    table(x$cluster)
}

# simplify gene & cell names
dimnames(x) <- list(
    paste0("gene", seq_len(nrow(x))),
    paste0("cell", seq_len(ncol(x))))

# save SCE to .rds
saveRDS(x, args[[2]])