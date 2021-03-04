suppressPackageStartupMessages({
    library(dplyr)
    library(purrr)
})

# args <- list(
#     x_ref = "results/qc-CellBench,H1975,cell_frq.rds",
#     y_ref = "results/qc-CellBench,H1975,cell_lls.rds",
#     x_sim = list.files("results", "qc-CellBench,H1975.*cell_frq,", full.names = TRUE),
#     y_sim = list.files("results", "qc-CellBench,H1975.*cell_lls,", full.names = TRUE))
# 
# wcs <- list(
#     metric1 = "cell_frq",
#     metric2 = "cell_lls")

x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)

df <- x %>% 
    rename(x = wcs$metric1) %>% 
    mutate(y = y[[wcs$metric2]])

dfs <- split(df, df$method, drop = TRUE)
ref <- which(names(dfs) == "reference")
sim <- dfs[-ref]; ref <- dfs[[ref]]

res <- lapply(sim, function(.) {
    group_by(., group, id) %>%
        group_map(
            .keep = TRUE, 
            ~data.frame(
                group = .x$group[1], 
                id = .x$id[1], 
                .dy(ref, .x)))
}) %>% 
    map(bind_rows) %>% 
    bind_rows(.id = "method")

saveRDS(res, args$res)