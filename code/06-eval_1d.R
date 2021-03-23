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

# 
# args<- list(ref = "results/qc_ref-CellBench,H1975,cell_cor.rds",
#             sim = c("results/qc_sim-CellBench,H1975,cell_cor,BASiCS.rds", "results/qc_sim-CellBench,H1975,cell_cor,SPsimSeq.rds"))
# wcs <- list(refset="CellBench", H1975=NA, type="gene", metric="avg")
this_metric <- paste0(wcs$type, '_', wcs$metric)
this_metric
if(this_metric != c("cell_cms")){
df <- .read_res(args$ref, args$sim)
print(head(df))
}else{df <- NA}

source(args$fun)

#TODO: take out this_metric != "cell_cms" once cms was implemented with proper parameters and does not only have zero values
if (!is.na(df)) {
  df <- group_by(df, group, id)
  res <- group_map(df, ~{
    df <- group_by(.x, method)
    dfs <- setNames(
      group_split(df), 
      group_keys(df)[[1]])
    i <- which(names(dfs) == "ref")
    vapply(dfs[-i], function(sim) 
      fun(sim[[this_metric]], 
          dfs[[i]][[this_metric]]),
      numeric(1))
  })
  res <- data.frame(
    group_keys(df), 
    t(data.frame(res))) %>% 
    pivot_longer(
      cols = -c(group, id), 
      names_to = "method", 
      values_to = "stat")
  res <- cbind(data.frame(refset = wcs$refset, 
                          subset = names(wcs)[2], 
                          type= wcs$type, 
                          metric=wcs$metric), res)

} else res <- NA

print(head(res))
saveRDS(res, args$res)
