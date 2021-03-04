# load required packages
suppressPackageStartupMessages({
    library(CellBench)
    library(SingleCellExperiment)
})

# load SCE from EH
sce <- load_sc_data()
ids <- names(sce)

# get genes shared across batches
gs <- lapply(sce, rownames)
gs <- Reduce(intersect, gs)

sce <- lapply(ids, function(id) 
{
    # subset shared genes
    x <- sce[[id]][gs, ]
    
    # simplify metadata
    rowData(x) <- NULL
    colData(x) <- DataFrame(
        batch = id,
        cluster = x$cell_line)
    metadata(x) <- list()
    
    # simplify gene & cell names
    dimnames(x) <- list(
        paste0("gene", seq_len(nrow(x))),
        paste0("cell", seq_len(ncol(x))))
    
    # make counts sparse & drop drop log-normalized counts
    y <- as(counts(x), "dgCMatrix")
    assays(x) <- list(counts = y)
    return(x)
})

# concatenate batches into single dataset
sce <- do.call(cbind, sce)

# write SCE to .rds
saveRDS(sce, args[[1]])