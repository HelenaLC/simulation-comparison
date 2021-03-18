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
    
    # make counts sparse & drop drop log-normalized counts
    y <- as(counts(x), "dgCMatrix")
    assays(x) <- list(counts = y)
    print(dim(x))
    return(x)
})

# concatenate batches into single dataset
sce <- do.call(cbind, sce)

# simplify gene & cell names
dimnames(sce) <- list(
    paste0("gene", seq_len(nrow(sce))),
    paste0("cell", seq_len(ncol(sce))))

print("size if whole dataset")
print(dim(sce))
# write SCE to .rds
saveRDS(sce, args[[1]])