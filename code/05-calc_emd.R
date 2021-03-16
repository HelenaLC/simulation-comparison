suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(emdist)
  library(tidyr)
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

x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)

### new stuff

x <- rename(x, x=paste0(wcs$type, '_', wcs$metric1))
y <- rename(y, y=paste0(wcs$type, '_', wcs$metric2))
y_ref <- y %>%
            filter(., method =="reference")

df <- x %>% group_by(group, id)
emd <- group_map(df, ~{
  d <- group_by(.x, .x$method)
  dfs <- setNames(group_split(d), group_keys(d)[[1]])
  # print(dfs)c
  i <- which(names(dfs) == "reference")
  
  curr_group <- .x$group[1]
  curr_id <- .x$id[1]
  y_df <- y %>%
            filter(., group==curr_group, id==curr_id)
  y_ref_curr <- y_ref %>%
                       filter(., group==curr_group, id==curr_id)
  
  result <- lapply(dfs[-i], function(s){
    
    curr_method <- s$method[1]
    y_sim <- y_df %>%
                  filter(., method==curr_method)
    # print("--")
    # print(head(y_subset))
    # print(head(s))
    # .emd(dfs[[i]], s)
    # print(.x$group[1])
    # print(.x$id[1])
    print(paste(curr_group, curr_id))
    print(curr_method)
    data.frame(group = .x$group[1],
               id = .x$id[1],
               emd = .emd_adapted(x_ref=dfs[[i]], x_sim=s, y_ref=y_ref_curr, y_sim= y_sim)) 
  })
  
}, .keep = TRUE)

res <- emd %>%
  map(., ~bind_rows(.x, .id="method")) %>%
  bind_rows(.)

print(res)

saveRDS(res, args$res)

# ####old stuff 
# 
# df <- x %>% 
#   rename(x = paste0(wcs$type, '_', wcs$metric1)) %>% 
#   mutate(y = y[[paste0(wcs$type, '_', wcs$metric2)]])
# 
# 
# # dfs <- split(df, df$method, drop = TRUE)
# # ref <- which(names(dfs) == "reference")
# # sim <- dfs[-ref]; ref <- dfs[[ref]]
# # 
# # df <- group_by(df, group, id)
# # ks <- group_map(df, ~{
# #   df <- group_by(.x, method)
# #   dfs <- setNames(
# #     group_split(df), 
# #     group_keys(df)[[1]])
# #   i <- which(names(dfs) == "reference")
# #   vapply(dfs[-i], function(sim) 
# #     .ks(sim[[paste0(wcs$type, '_', wcs$metric)]], 
# #         dfs[[i]][[paste0(wcs$type, '_', wcs$metric)]]),
# #     numeric(1))
# # })
# 
# df <- group_by(df, group, id)
# emd <- group_map(df, ~{
#   d <- group_by(.x, .x$method)
#   dfs <- setNames(group_split(d), group_keys(d)[[1]])
#   i <- which(names(dfs) == "reference")
#   
#   # dfs <- split(.x, .x$method, drop = TRUE)
#   # print(length(dfs))
#   # ref <- which(names(dfs) == "reference")
#   # sim <- dfs[-ref]
#   # ref <- dfs[[ref]]
#   # print("ref")
#   # print(dim(ref))
#   # print(head(ref))
#   # print("sim")
#   # print(dim(sim$BASiCS))
#   # print(head(sim$BASiCS))
#   # 
#   result <- lapply(dfs[-i], function(s){
#     # .emd(dfs[[i]], s)
#     # print(.x$group[1])
#     # print(.x$id[1])
#     data.frame(group = .x$group[1],
#                id = .x$id[1],
#                emd = .emd(dfs[[i]], s))
#   })
#   # print("result")
#   # print(result)
# }, .keep=TRUE)
# 
# res <- emd %>%
#             map(., ~bind_rows(.x, .id="method")) %>%
#             bind_rows(.)
#   # bind_rows(map(emd, ~bind_rows(.x, .id="method")))
# 
# 
# # res <- data.frame(
# #   group_keys(df), 
# #   t(data.frame(ks))) %>% 
# #   pivot_longer(
# #     cols = -c(group, id), 
# #     names_to = "method", 
# #     values_to = "stat")
# 
# # res <- lapply(sim, function(.) {
# #   df <- 
# #   group_by(., group, id) %>%
# #     group_map(
# #       .keep = TRUE, 
# #       ~data.frame(
# #         group = .x$group[1], 
# #         id = .x$id[1], 
# #         .emd(ref, .x)))
# # }) %>% 
# #   map(bind_rows) %>% 
# #   bind_rows(.id = "method")
# # 
# 
# # 
# # res <- lapply(sim, function(.) {
# #   
# #   group_by(., group, id) %>%
# #     group_map(
# #       .keep = TRUE, 
# #       ~data.frame(
# #         group = .x$group[1], 
# #         id = .x$id[1], 
# #         .emd(ref, .x)))
# # }) %>% 
# #   map(bind_rows) %>% 
# #   bind_rows(.id = "method")
# 
# 
# 
# saveRDS(res, args$res)