suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

# load SCE from URL
con <- url("https://www.dropbox.com/s/i8mwmyymchx8mn8/x.all_classified.technologies.RData?raw=1")
x <- get(load(con))
close(con)

# drop log-normalized counts
assay(x, "logcounts") <- NULL

# drop feature metadata
rowData(x) <- NULL

# subset & rename cell metadata
colData(x) <- DataFrame(
    batch = x$batch,
    cluster = x$nnet2)

# simplify gene & cell names
dimnames(x) <- list(
    paste0("gene", seq_len(nrow(x))),
    paste0("cell", seq_len(ncol(x))))

saveRDS(x, args[[1]])