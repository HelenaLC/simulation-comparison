# load required packages
suppressPackageStartupMessages({
    library(Seurat)
    library(SeuratData)
    library(SingleCellExperiment)
})

if (!require(panc8.SeuratData))
    InstallData("panc8.SeuratData")

# load data as 'Seurat' object
data("panc8")
x <- as.SingleCellExperiment(panc8)

# drop log-normalized counts
# (these are identical to counts)
assay(x, "logcounts") <- NULL

# for each batch, keep largest replicate
ns <- table(x$tech, x$replicate)
x <- x[, x$replicate %in% apply(ns, 1, 
    function(.) colnames(ns)[which.max(.)])]

# drop undetected genes
x <- x[rowSums(assay(x)) > 0, ]

# subset & rename cell metadata
colData(x) <- DataFrame(
    batch = x$tech, 
    cluster = x$celltype)

# simplify gene & cell names
dimnames(x) <- list(
    paste0("gene", seq_len(nrow(x))),
    paste0("cell", seq_len(ncol(x))))

# save SCE to .rds
print(dim(x))
saveRDS(x, args[[1]])