suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
})
# args <- list(
#     x_ref = "results/qc_ref-CellBench,H1975,cell_frq.rds",
#     y_ref = "results/qc_ref-CellBench,H1975,cell_lls.rds",
#     x_sim = c("results/qc_sim-CellBench,H1975,cell_frq,BASiCS.rds", "results/qc_sim-CellBench,H1975,cell_frq,SPsimSeq.rds"),
#     y_sim = c("results/qc_sim-CellBench,H1975,cell_lls,BASiCS.rds", "results/qc_sim-CellBench,H1975,cell_lls,SPsimSeq.rds"),
#     res =  "results/dy-CellBench,H1975,cell_frq,cell_lls.rds" )
# 
# wcs <- list(
#     refset = "CellBench",
#     H1975 = NA,
#     type = "cell",
#     metric1 = "frq",
#     metric2 = "lls")


x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)

df <- x %>% 
  rename(x = paste0(wcs$type, '_', wcs$metric1)) %>% 
  mutate(y = y[[paste0(wcs$type, '_', wcs$metric2)]])

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