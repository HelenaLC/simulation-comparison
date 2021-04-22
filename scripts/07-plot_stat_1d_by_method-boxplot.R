source(args$fun)
df <- .read_res(args$res)

plt <- ggplot(df, 
    aes(reorder_within(metric, stat, group), 
        stat, col = metric, fill = metric)) +
    facet_grid(~ group, scales = "free_x") +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_y_continuous(limits = c(0, 1)) +
    scale_fill_manual(values = .metrics_pal) +
    scale_colour_manual(values = .metrics_pal) +
    labs(x = NULL, y = .stats1d_lab[wcs$stat1d]) +
    ggtitle(paste("method:", wcs$method))

thm <- theme(
    aspect.ratio = 2,
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

p <- .prettify(plt, thm)
n <- length(unique(df$group))
saveRDS(p, args$ggp)
ggsave(args$plt, p, width = 4+3*n, height = 6, units = "cm")