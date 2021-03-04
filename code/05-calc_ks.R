suppressPackageStartupMessages({
    library(dplyr)
    library(jsonlite)
    library(tidyr)
})
# 
# wcs <- list(metric = "cell_lls")
# args <- list(
#     con = "config/methods.json",
#     ref = "results/qc-Mereu20,CD4T,cell_lls.rds",
#     sim = list.files("results", "Mereu20,CD4T,cell_lls,", full.names = TRUE))

df <- .read_res(args$ref, args$sim)
if (!is.na(df)) {
    df <- group_by(df, group, id)
    ks <- group_map(df, ~{
        df <- group_by(.x, method)
        dfs <- setNames(
            group_split(df), 
            group_keys(df)[[1]])
        i <- which(names(dfs) == "reference")
        vapply(dfs[-i], function(sim) 
            .ks(sim[[wcs$metric]], 
                dfs[[i]][[wcs$metric]]),
            numeric(1))
    })
    res <- data.frame(
        group_keys(df), 
        t(data.frame(ks))) %>% 
        pivot_longer(
            cols = -c(group, id), 
            names_to = "method", 
            values_to = "stat")
} else res <- NA
saveRDS(res, args$res)