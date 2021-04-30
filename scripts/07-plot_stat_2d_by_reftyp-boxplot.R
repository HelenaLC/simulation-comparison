source(args$fun)

df <- .read_res(args$res)

if (wcs$reftyp == "g") 
    df <- df %>% 
    rowwise() %>% 
    mutate(
        group = as.character(group),
        group = case_when(
            group != "global" ~ "group", 
            TRUE ~ group)) %>% 
    ungroup()

df <- df %>% mutate(
    group = relevel(factor(group), ref = "global"), 
    metrics = paste(metric1, metric2, sep = "\n"))

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
    "reorder_within(method, stat, metrics)", 
    "stat", col = col, fill = fill, group = group)) +
    facet_wrap(~ metrics, nrow = 1, 
        scales = switch(wcs$stat2d, ks2 = "free_x", emd = "free")) +
    geom_boxplot(
        outlier.size = 0.25, outlier.alpha = 1,
        size = 0.25, alpha = 0.25, key_glyph = "point") + 
    scale_fill_manual(values = pal) +
    scale_color_manual(values = .methods_pal) +
    scale_y_continuous(
        switch(wcs$stat2d, ks2 = "KS statistic", emd = "EMD"),
        n.breaks = 3, limits = c(0, switch(wcs$stat2d, ks2 = 1, emd = NA)))

thm <- theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)

saveRDS(fig, args$ggp)
ggsave(args$plt, fig, width = 18, height = 4, units = "cm")
