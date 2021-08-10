suppressPackageStartupMessages({
  library(SymSim)
  library(SingleCellExperiment)
})

fun <- function(x) {
    args <- intersect(
        names(x$params),
        names(formals(SimulateTrueCounts)))
    args <- c(x$params[args], list(randseed = 1234))
    y <- do.call(SimulateTrueCounts, args)
    
    data("gene_len_pool")
    gene_len <- sample(gene_len_pool, args$ngenes, TRUE)
    
    args <- intersect(
        names(x$params),
        names(formals(True2ObservedCounts)))
    args <- c(x$params[args], list(
        true_counts = y$counts, 
        meta_cell = y$cell_meta, 
        gene_len = gene_len))
    z <- do.call(True2ObservedCounts, args)
    
    if (x$params$nbatch > 1) {
        z <- DivideBatches(
            observed_counts_res = z, 
            nbatch = x$params$nbatch)
        cd <- DataFrame(batch = x$batch)
    } else cd <- make_zero_col_DFrame(ncol(z$counts))
    SingleCellExperiment(list(counts = z$counts), colData = cd)
}