# wcs <- list(val = "cms")
# args <- list(
#     fun = "code/utils.R",
#     res = list.files("outs", "^batch_res-", full.names = TRUE),
#     rds = sprintf("plts/batch-boxplot_by_method_%s.rds", wcs$val),
#     pdf = sprintf("plts/batch-boxplot_by_method_%s.pdf", wcs$val))

source(args$fun)

res <- .read_res(args$res) %>%
    dplyr::rename(sim_method = method) 

df <- .eval_batch(res)
    
plt <- ggplot(df, aes(
    reorder_within(
        x = batch_method, 
        by = .data[[wcs$val]], 
        within = sim_method, 
        fun = \(.) mean(abs(.))), 
    y = .data[[wcs$val]], 
    col = batch_method, 
    fill = batch_method)) +
    facet_grid(~ sim_method, scales = "free_x") +
    geom_hline(yintercept = 0, size = 0.2) +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_y_continuous(.batch_labs[wcs$val], n.breaks = 3)

thm <- theme(
    legend.title = element_blank(),
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 15, height = 6, units = "cm")
