# wcs <- list(val = "cms")
# args <- list(
#     uts1 = "code/utils-plotting.R",
#     uts2 = "code/utils-integration.R",
#     res = list.files("outs", "^batch_res-", full.names = TRUE),
#     rds = sprintf("plts/batch-boxplot_by_method_%s.rds", wcs$val),
#     pdf = sprintf("plts/batch-boxplot_by_method_%s.pdf", wcs$val))

source(args$uts1)
source(args$uts2)

res <- .read_res(args$res)

df <- res %>% 
    .cms_ldf() %>% 
    .bcs(n = 1) # average across cells but not batches

lim <- switch(wcs$val, bcs = c(0, 1), c(-0.5, 0.5))

plt <- ggplot(df, aes(
    reorder_within(batch_method, .data[[wcs$val]], sim_method, median), 
    .data[[wcs$val]], col = batch_method, fill = batch_method)) +
    facet_grid(~ sim_method, scales = "free_x") +
    geom_hline(yintercept = c(0, 1), size = 0.1) +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_y_continuous(
        .batch_labs[wcs$val], 
        limits = lim, 
        n.breaks = 3)

thm <- theme(
    legend.title = element_blank(),
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 15, height = 6, units = "cm")
