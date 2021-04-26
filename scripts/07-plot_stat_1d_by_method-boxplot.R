source(args$fun)
df <- .read_res(args$res)

plt <- ggplot(
    filter(df, group == "global"), 
    aes(reorder_within(metric, stat, method), 
        stat, col = metric, fill = metric)) +
    facet_wrap(~ method, nrow = 2, scales = "free_x") +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_fill_manual(values = .metrics_pal) +
    scale_colour_manual(values = .metrics_pal) +
    labs(x = NULL, y = .stats1d_lab[wcs$stat1d])

thm <- theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

(p <- .prettify(plt, thm))
saveRDS(p, args$ggp)
ggsave(args$plt, p, width = 15, height = 6, units = "cm")
