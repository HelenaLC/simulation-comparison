# load required packages
suppressPackageStartupMessages({
    library(ExperimentHub)
    library(SingleCellExperiment)
})

fun <- \()
{
    # load SCE from EH
    eh <- ExperimentHub()
    q <- query(eh, "Kang18_8vs8")
    x <- eh[[q$ah_id]]
    
    # keep reference samples only
    x <- x[, x$stim == "ctrl"]
    
    # drop unassigned & multiplet cells
    x <- x[, !is.na(x$cell)]
    x <- x[, x$multiplets == "singlet"]
    
    # drop undetected genes
    x <- x[rowSums(counts(x)) > 0, ]
    
    # convert counts to sparse matrix
    counts(x) <- as(counts(x), "dgCMatrix")
    
    # drop feature metadata
    rowData(x) <- NULL
    
    # subset & rename cell metadata
    colData(x) <- DataFrame(
        batch = factor(x$ind),
        cluster = x$cell,
        row.names = NULL)
    
    return(x)
}