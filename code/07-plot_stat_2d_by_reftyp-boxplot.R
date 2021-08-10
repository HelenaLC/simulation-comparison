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
    metrics = paste(metric1, metric2, sep = "\n"),
    group = relevel(droplevels(factor(group)), ref = "global"))

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
    pal <- .groups_pal
    pal <- pal[levels(df$group)]
}

switch(wcs$stat2d, 
    ks2 = {
        ylab <- "KS statistic"
        scales <- "free_x"
        ylims <- c(0, 1)
    }, 
    emd = {
        ylab <- "EMD"
        scales <- "free"
        ylims <- c(0, NA)
    }
)

plt <- ggplot(df, aes_string(
    "reorder_within(method, stat, metrics)", 
    "stat", col = col, fill = fill, group = group)) +
    facet_wrap(~ metrics, nrow = 1, scales = scales) +
    geom_boxplot(
        outlier.size = 0.25, outlier.alpha = 1,
        size = 0.25, alpha = 0.25, key_glyph = "point") + 
    scale_fill_manual(values = pal) +
    scale_color_manual(values = .methods_pal[levels(df$method)]) +
    scale_y_continuous(limits = ylims, n.breaks = 3) +
    labs(x = NULL, y = ylab)

thm <- theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)
if (!is.null(fig$guides$col))
    fig$guides$col$ncol <- 2

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 18, height = 4, units = "cm")
