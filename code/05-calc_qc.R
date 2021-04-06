source(args$fun)

# each QC script should specify
# ppFUN:   function to apply to the SCE for PreProcessing
# qcFUN:   function to compute the Quality Control metric
#          (both FUNs should input & output a SCE)
# groups:  for which to compute the QC metric 
#          (global, cluster, batch, NULL for all)
# n_genes: number of genes to sample - globally  (NULL for all)
# n_cells: number of cells to sample - per group (NULL for all)

if (exists("ppFUN")) {
    stopifnot(is.function(ppFUN)) 
} else {
    # do nothing
    ppFUN <- function(.) . 
}

if (exists("qcFUN")) {
    stopifnot(is.function(qcFUN)) 
} else {
    stop("'qcFUN' needs to be specified")
}

choices <- eval(formals(.calc_qc)$groups)
if (exists("groups") && !is.null(groups)) {
    groups <- match.arg(groups, choices, several.ok = TRUE)
} else {
    groups <- choices
}

if (exists("n_genes") && !is.null(n_genes)) {
    stopifnot(is.numeric(n_genes), length(n_genes) == 1)
} else {
    # use all
    n_genes <- NULL 
}

if (exists("n_cells") && !is.null(n_cells)) {
    stopifnot(is.numeric(n_cells), length(n_cells) == 1)
} else {
    # use all
    n_cells <- NULL
}

# ------------------------------------------------------------------------------

sce <- readRDS(args$sce)
sce <- ppFUN(sce)
res <- .calc_qc(sce, 
    fun = qcFUN, 
    n_genes = n_genes,
    n_cells = n_cells,
    groups = groups)

if (is.null(res)) {
    df <- NULL
} else {
    ss <- strsplit(wcs$refset, "\\.")[[1]]
    type.metric <- paste(wcs$type, wcs$metric, sep = ".")
    method <- ifelse(is.null(wcs$method), "ref", wcs$method)
    df <- data.frame(
        datset = ss[1],
        subset = ss[2],
        refset = wcs$refset, 
        type = wcs$type, 
        metric = wcs$metric, 
        type.metric,
        method, res)
}
print(head(df))
saveRDS(df, args$res)