# split cell indices into list
# - global = list w/ one element (all cells)
# - batch = list w/ one element per batch (optional)
# - cluster = list w/ one element per cluster (optional)
.split_cells <- function(sce, 
    i = c("global", "batch", "cluster"))
{
    names(j) <- j <- intersect(i, names(colData(sce)))
    cs <- lapply(j, function(.) {
        ids <- droplevels(factor(sce[[.]]))
        split(seq(ncol(sce)), ids)
    })
    if ("global" %in% i)
        cs <- c(list(global = list(foo = seq(ncol(sce)))), cs)
    return(cs)
}

# split genes by group = "cluster","batch", "sample". 
# Then per group calculate the qc with the FUN function(which is a metric)
# returns a dataframe with cols:  group | id | metric_name
.calc_qc <- function(sce, fun, 
    n_genes = NULL, n_cells = NULL, 
    groups = c("global", "cluster", "batch")) 
{
    suppressPackageStartupMessages({
        library(dplyr)
        library(purrr)
    })
    if (is.null(groups)) {
        groups <- eval(formals(.calc_qc)$groups)
    } else {
        groups <- match.arg(groups, several.ok = TRUE)
    }
    # split cells into groups
    idx <- .split_cells(sce, groups)
    # downsample to at most 'n_genes' in total
    if (!is.null(n_genes)) {
        n_genes <- min(n_genes, nrow(sce))
        gs <- sample(nrow(sce), n_genes)
        sce <- sce[gs, ]
    }
    # downsample to at most 'n_cells' per group
    if (!is.null(n_cells)) {
        idx <- map_depth(idx, -1, ~{
            n_cells <- min(n_cells, length(.x))
            sample(.x, n_cells)
        })
    }
    # compute QC metric per group
    res <- map_depth(idx, -1, ~{
        data.frame(
            row.names = NULL, 
            value = fun(sce[, .x]))
    })
    # join into single table
    res <- map_depth(res, 1, bind_rows, .id = "id")
    res <- bind_rows(res, .id = "group")
    if (nrow(res) != 0) return(res)
}