suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

fun <- \()
{
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
    
    return(x)
}