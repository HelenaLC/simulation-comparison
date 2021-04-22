source(args$fun)
df <- .read_res(args$res)

if (wcs$reftyp == "n") {
    col <- "method"
    fill <- "method"
    group <- NULL
    pal <- .methods_pal
} else {
    df$foo <- with(df, paste0(group, method))
    col <- "method"
    fill <- "group"
    group <- "foo"
    pal <- .groups_pal
}

plt <- ggplot(df, aes_string(
    "reorder_within(method, stat, metric)", 
    "stat", col = col, fill = fill, group = group)) +
    facet_wrap(~ metric, nrow = 2, scales = "free") +
    geom_boxplot(
        outlier.size = 0.25, outlier.alpha = 1,
        size = 0.25, alpha = 0.25, key_glyph = "point") + 
    scale_y_continuous(
        limits = switch(wcs$stat1d, 
            ks = c(0, 1), ws = c(0, NA))) +
    scale_fill_manual(values = pal) +
    scale_color_manual(values = .methods_pal)

thm <- theme(
    axis.title = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

p <- .prettify(plt, thm)
saveRDS(p, args$ggp)
ggsave(args$plt, p, width = 15, height = 6, units = "cm")