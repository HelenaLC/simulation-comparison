suppressPackageStartupMessages({
    library(edgeR)
    library(matrixStats)
    library(SingleCellExperiment)
})

fun <- function(x, min_count = 1, min_cells = 10, min_genes = 20) {
    vars <- c("sample", "batch", "cluster")
    names(vars) <- vars <- intersect(vars, names(colData(x)))
    colData(x) <- colData(x)[vars]
    
    # assure cell metadata columns are factors
    for (v in vars) {
        if (!is.factor(x[[v]])) 
            x[[v]] <- as.factor(x[[v]])
        x[[v]] <- droplevels(x[[v]])
        n <- nlevels(x[[v]])
        if (n == 1) {
            vars <- setdiff(vars, v)
            next
        }
        # ids <- paste0(v, seq_len(n))
        # x[[v]] <- factor(x[[v]], labels = ids)
    }
    
    # keep cells with ≥ 'min_genes' detected;
    # keep genes with ≥ 'min_count's in ≥ 'min_cells'
    gs <- rowSums(counts(x) > min_count) >= min_cells
    if (sum(gs) == 0) 
        stop("No genes remaining.",
            " Please decrease min_count and/or min_cells.")
    cs <- colSums(counts(x) > 0) >= min_genes
    if (sum(cs) == 0) 
        stop("No cells remaining.",
            " Please decrease min_genes.")
    x <- x[gs, cs]
    
    # construct model formula
    f <- "~ 1"
    for (v in vars)
        f <- paste(f, v, sep = "+")
    
    # construct design matrix
    cd <- as.data.frame(droplevels(colData(x)))
    mm <- model.matrix(as.formula(f), data = cd)
    
    # estimate NB parameters
    y <- DGEList(counts(x))
    y <- calcNormFactors(y)
    y <- estimateDisp(y, mm)
    fit <- glmFit(y, prior.count = 0)
    x$offset <- c(fit$offset)
    
    # split betas by variable
    bs <- fit$coefficients
    dfs <- lapply(vars, function(v) {
        pat <- paste0("^", v)
        i <- grep(pat, colnames(bs))
        df <- DataFrame(bs[, i])
        colnames(df) <- gsub(pat, "", colnames(bs)[i])
        return(df)
    })
    # store NB parameters in feature metadata
    df <- DataFrame(beta0 = bs[, 1])
    if (length(vars) != 0) 
        df <- cbind(df, DataFrame(lapply(dfs, I)))
    rowData(x)$beta <- df
    rowData(x)$disp <- fit$dispersion
    
    # drop genes for which estimation failed
    x <- x[!rowAnyNAs(bs), ]
    
    # return SCE
    return(x)
}