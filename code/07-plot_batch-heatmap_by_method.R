# wcs <- list(val = "cms")
# args <- list(
#     uts1 = "code/utils-plotting.R",
#     uts2 = "code/utils-integration.R",
#     rds = paste0("plts/batch-heatmap_by_method_", wcs$val, ".rds"),
#     pdf = paste0("plts/batch-heatmap_by_method_", wcs$val, ".pdf"),
#     res = list.files("outs", "^batch_res", full.names = TRUE))

source(args$uts1)
source(args$uts2)

res <- .read_res(args$res)

df <- res %>% 
    .cms_ldf() %>% 
    .bcs(n = 2) # average across cells & batches

max <- ceiling(max(df$bcs)/0.1)*0.1
lim <- switch(wcs$val, bcs = c(0, max), c(-0.5, 0.5))

plt <- ggplot(df, aes(
    reorder_within(batch_method, .data[[wcs$val]], sim_method, median), 
    refset, fill = .data[[wcs$val]])) +
    facet_grid(~ sim_method, scales = "free_x") +
    geom_tile(col = "white") +
    scale_fill_distiller(
        .batch_labs[wcs$val],
        palette = "RdYlBu",
        na.value = "lightgrey",
        limits = lim,
        n.breaks = 3) +
    coord_cartesian(expand = FALSE) +
    scale_x_reordered() +
    scale_y_reordered() 

thm <- theme(
    axis.title = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 15, height = 6, units = "cm")