suppressPackageStartupMessages({
    library(dplyr)
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
#     metric2 = "var",
#     stat_2d = "emd")

x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)
FUN <- get(paste0(".", wcs$stat_2d))

df <- x %>%
  rename(x = paste0(wcs$type, '_', wcs$metric1)) %>%
  mutate(y = y[[paste0(wcs$type, '_', wcs$metric2)]])

sub <- df[sample(nrow(df), 2e3), ]

res <- sub %>% 
    group_by(group, id) %>% 
    group_map(.keep = TRUE, ~{
        df <- group_by(.x, .x$method)
        dfs <- setNames(
            group_split(df),
            group_keys(df)[[1]])
        
        idx <- which(names(dfs) == "reference")
        ref <- dfs[[idx]]
    
        res <- lapply(dfs[-idx], function(sim)
            data.frame(stat = FUN(ref, sim)))
            
        res <- bind_rows(res, .id = "method")
        cbind(.x[1, c("group", "id")], res)
    }) %>% bind_rows()

print(res)
saveRDS(res, args$res)
