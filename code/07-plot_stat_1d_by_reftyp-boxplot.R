source(args$fun)
df <- .read_res(args$res)
head(df)

if (wcs$reftyp == "g") 
    df <- df %>% 
    rowwise() %>% 
    mutate(
        group = as.character(group),
        group = case_when(
            group != "global" ~ "group", 
            TRUE ~ group)) %>% 
    ungroup()

df <- mutate(df, 
    group = relevel(
        factor(group), 
        ref = "global"))

if (wcs$reftyp == "n") {
    col <- "method"
    fill <- "method"
    group <- NULL
    pal <- .methods_pal[levels(df$method)]
} else {
    df$foo <- with(df, paste0(group, method))
    col <- "method"
    fill <- "group"
    group <- "foo"
    pal <- .groups_pal[levels(df$group)]
}

switch(wcs$stat1d,
    ks = {
        ylab <- "KS statistic"
        scales <- "free_x"
        ylims <- c(0, 1)
    }, 
    ws = {
        ylab <- "Wasserstein metric"
        scales <- "free"
        ylims <- c(0, NA)
    }
)

plt <- ggplot(df, aes_string(
    "reorder_within(method, stat, metric)", 
    "stat", col = col, fill = fill, group = group)) +
    facet_wrap(~ metric, nrow = 2, scales = scales) +
    geom_boxplot(
        outlier.size = 0.25, outlier.alpha = 1,
        size = 0.25, alpha = 0.25, key_glyph = "point") + 
    scale_fill_manual(values = pal) +
    scale_color_manual(values = .methods_pal[levels(df$method)]) +
    scale_y_continuous(limits = ylims, n.breaks = 3) +
    labs(x = NULL, y = ylab)

thm <- theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)
saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 6, units = "cm")