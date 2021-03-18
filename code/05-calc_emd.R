suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(emdist)
  library(tidyr)
  library(MASS)
})
# args <- list(
#     x_ref = "results/qc_ref-CellBench,H1975,gene_avg.rds",
#     y_ref = "results/qc_ref-CellBench,H1975,gene_var.rds",
#     x_sim = c("results/qc_sim-CellBench,H1975,gene_avg,BASiCS.rds", "results/qc_sim-CellBench,H1975,gene_avg,SPsimSeq.rds"),
#     y_sim = c("results/qc_sim-CellBench,H1975,gene_var,BASiCS.rds", "results/qc_sim-CellBench,H1975,gene_var,SPsimSeq.rds"),
#     res =  "results/emd-CellBench,H1975,gene_avg,gene_var.rds" )
# 
# wcs <- list(
#     refset = "CellBench",
#     H1975 = NA,
#     type = "gene",
#     metric1 = "avg",
#     metric2 = "var")

# args <- list(
#     x_ref = "results/qc_ref-CellBench,H1975,cell_frq.rds",
#     y_ref = "results/qc_ref-CellBench,H1975,cell_lls.rds",
#     x_sim = "results/qc_sim-CellBench,H1975,cell_frq,BASiCS.rds",
#     y_sim = "results/qc_sim-CellBench,H1975,cell_lls,BASiCS.rds",
#     res =  "results/emd-CellBench,H1975,cell_frq,cell_lls.rds" )
# 
# wcs <- list(
#     refset = "CellBench",
#     H1975 = NA,
#     type = "cell",
#     metric1 = "frq",
#     metric2 = "lls")


# args <- list(
#   x_ref = "results/qc_ref-CellBench,H1975,gene_avg.rds",
#   y_ref =  "results/qc_ref-CellBench,H1975,gene_cor.rds",
#   x_sim =  c("results/qc_sim-CellBench,H1975,gene_avg,BASiCS.rds","results/qc_sim-CellBench,H1975,gene_avg,SPsimSeq.rds"  ),
#   y_sim = c("results/qc_sim-CellBench,H1975,gene_cor,BASiCS.rds"  , "results/qc_sim-CellBench,H1975,gene_cor,SPsimSeq.rds" )
# )
# wcs <- list(type ="gene", metric1="avg",metric2="cor")

# args <- list(
#   x_ref = "results/qc_ref-panc8,indrop_alpha,gene_avg.rds",
#   y_ref = "results/qc_ref-panc8,indrop_alpha,gene_var.rds",
#   x_sim = c("results/qc_sim-panc8,indrop_alpha,gene_avg,splatter.rds", "results/qc_sim-panc8,indrop_alpha,gene_avg,SPsimSeq.rds", "results/qc_sim-panc8,indrop_alpha,gene_avg,SymSim.rds"),
#   y_sim = c( "results/qc_sim-panc8,indrop_alpha,gene_var,splatter.rds", "results/qc_sim-panc8,indrop_alpha,gene_var,SPsimSeq.rds", "results/qc_sim-panc8,indrop_alpha,gene_var,SymSim.rds" )
# )
# 
# wcs <- list(type ="gene", metric1="avg",metric2="var")



if (wcs$metric1 == "cor" || wcs$metric2 =="cor") {
  print("saving nothing")
  saveRDS(NA, args$res) #originally had NULL
}else{
  
  
x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)


df <- x %>%
  rename(x = paste0(wcs$type, '_', wcs$metric1)) %>%
  mutate(y = y[[paste0(wcs$type, '_', wcs$metric2)]])


df <- group_by(df, group, id)
emd <- group_map(df, ~{
  
  d <- group_by(.x, .x$method)
  dfs <- setNames(group_split(d), group_keys(d)[[1]])
  i <- which(names(dfs) == "reference")
  
  result <- lapply(dfs[-i], function(s){
    data.frame(group = .x$group[1],
               id = .x$id[1],
               emd = .emd(dfs[[i]][c("x","y")], s[c("x","y")]))
  })
}, .keep=TRUE)

res <- emd %>%
            map(., ~bind_rows(.x, .id="method")) %>%
            bind_rows(.)

print(res)
saveRDS(res, args$res)
}