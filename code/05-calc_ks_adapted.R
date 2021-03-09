suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})
# wcs <- list(refset="CellBench", H1975=NA, type="gene", metric="avg")
# args <- list(
#   ref = "results/qc_ref-panc8,indrop_alpha,gene_avg.rds",
#   sim = c("results/qc_sim-panc8,indrop_alpha,gene_avg,splatter.rds","results/qc_sim-panc8,indrop_alpha,gene_avg,SPsimSeq.rds"),
#   res = "results/ks-panc8,indrop_alpha,gene_avg.rds"
# )

# args <- list(
#   ref = "results/qc_ref-CellBench,H1975,gene_var.rds",
#   sim = c("results/qc_sim-CellBench,H1975,gene_var,BASiCS.rds","results/qc_sim-CellBench,H1975,gene_var,SPsimSeq.rds"),
#   res = "results/ks-CellBench,H1975,gene_var.rds"
# )

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
      .ks(sim[[paste0(wcs$type, '_', wcs$metric)]], 
          dfs[[i]][[paste0(wcs$type, '_', wcs$metric)]]),
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