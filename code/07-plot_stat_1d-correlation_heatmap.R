# args <- list(
#     fun = "code/utils.R",
#     rds = "plts/stat_1d-correlation_heatmap.rds",
#     pdf = "plts/stat_1d-correlation_heatmap.pdf",
#     res = list.files("outs", "stat_1d.*ks\\.rds", full.names = TRUE))

source(args$fun)
res <- .read_res(args$res)

df <- res %>% 
    mutate(refset = paste(datset, subset, sep = ",")) %>% 
    select(-c(datset, subset)) %>% 
    # average across groups
    group_by(refset, method, metric, group) %>% 
    summarise_at("stat", mean) %>% 
    # keep group-level comparisons only
    dplyr::mutate(n = n()) %>% 
    ungroup() %>% 
    filter(group != "global" | n == 1) %>%  
    select(-c(group, n)) %>% 
    # correlate b/w summaries, across methods & refsets
    pivot_wider(names_from = metric, values_from = stat) %>% 
    select(any_of(names(.metrics_lab))) %>% 
    cor(method = "pearson") 

mat <- as.matrix(df)
mat[is.na(mat)] <- 0
nms <- .metrics_lab[rownames(mat)]
rownames(mat) <- colnames(mat) <- nms

fig <- pheatmap::pheatmap(mat, 
    fontsize = 9, 
    cellwidth = 15,
    cellheight = 15,
    border_color = NA,
    treeheight_row = 30,
    treeheight_col = 30,
    legend_breaks = c(0, 0.5, 1),
    color = colorRampPalette(rev(brewer.pal(9, "RdYlBu")))(100))

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 12, height = 11, units = "cm")
