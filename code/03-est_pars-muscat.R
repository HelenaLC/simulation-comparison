suppressPackageStartupMessages({
    library(muscat)
    library(SingleCellExperiment)
})

fun <- function(x) {
    vars <- c("cluster", "batch", "group")
    vars <- setdiff(vars, names(colData(x)))
    for (v in vars) x[[v]] <- "foo"
    
    y <- prepSCE(x, 
        kid = "cluster",
        sid = "batch",
        gid = "group",
        drop = TRUE)

    z <- prepSim(y,
        min_size = NULL,
        verbose = FALSE)
}
