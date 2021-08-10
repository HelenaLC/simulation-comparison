suppressPackageStartupMessages({
    library(SC3)
    library(scater)
    library(SingleCellExperiment)
})

fun <- \(x) 
{
    if (is.null(rownames(x)))
        rownames(x) <- paste0("gene", seq(nrow(x)))
    
    if (!is.matrix(y <- counts(x)))
        counts(x) <- as.matrix(y)
    
    n <- round(ncol(x)/2)
    x <- logNormCounts(x)
    k <- length(unique(x$cluster))
    rowData(x)$feature_symbol <- rownames(x)
    
    y <- sc3_prepare(x,
        gene_filter = FALSE,
        svm_max = 0,
        svm_num_cells = n,
        n_cores = 1,
        rand_seed = 1)

    y <- sc3(y, 
        ks = k, 
        gene_filter = FALSE,
        biology = FALSE,
        k_estimator = FALSE,
        svm_max = 0,
        svm_num_cells = n,
        n_cores = 1,
        rand_seed = 1)
    
    y <- sc3_run_svm(y, k)
    y[[grep("sc3", names(colData(y)))]]
}