source(args$fun)
df <- .read_res(args$res)
df <- filter(df, group == "global")

xo <- df %>% 
    group_by(method, metric, datset) %>% 
    summarise_at("stat", mean) %>% 
    summarise_at("stat", mean) %>% 
    summarise_at("stat", mean) %>% 
    arrange(stat) %>% 
    pull("method")

plt <- ggplot(
    mutate(df, method = factor(method, xo)), 
    aes(reorder_within(metric, stat, method), 
        stat, col = metric, fill = metric)) +
    facet_wrap(~ method, nrow = 3, scales = "free_x") +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_fill_manual(values = .metrics_pal) +
    scale_colour_manual(values = .metrics_pal) +
    scale_y_continuous(limits = c(0, NA)) +
    labs(x = NULL, y = .stats1d_lab[wcs$stat1d])

thm <- theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)
saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")
