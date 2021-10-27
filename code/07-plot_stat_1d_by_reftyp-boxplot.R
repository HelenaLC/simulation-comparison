# wcs <- list(reftyp = "n", stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("stat_1d_by_reftyp-boxplot,%s,%s.rds", wcs$reftyp, wcs$stat1d),
#     pdf = sprintf("stat_1d_by_reftyp-boxplot,%s,%s.pdf", wcs$reftyp, wcs$stat1d))

source(args$fun)
res <- readRDS(args$res)

df <- res %>% 
    # keep data of interest
    filter(
        reftyp == wcs$reftyp, 
        stat1d == wcs$stat1d) %>%
    .filter_res() %>% 
    # scale values b/w 0 and 1 for visualization
    group_by(metric) %>% 
    mutate(stat = stat/max(stat, na.rm = TRUE))

pal <- .methods_pal[levels(df$method)]
lab <- parse(text = paste(
    sep = "~",
    sprintf("bold(%s)", LETTERS), 
    gsub("\\s", "~", names(pal))))

anno <- df %>% 
    group_by(method, metric) %>% 
    summarize_at("stat", median) %>% 
    mutate(letter = LETTERS[match(method, levels(method))])

plt <- ggplot(df, aes(
    reorder_within(method, stat, metric, median), 
    stat, col = method, fill = method)) +
    facet_wrap(~ metric, nrow = 3, scales = "free_x") +
    geom_boxplot(
        outlier.size = 0.25, outlier.alpha = 1,
        size = 0.25, alpha = 0.25, key_glyph = "point") + 
    geom_text(data = anno, 
        size = 1.5, color = "black", 
        aes(label = letter, y = -0.075)) + 
    scale_fill_manual(values = pal, labels = lab) +
    scale_color_manual(values = pal, labels = lab) +
    scale_x_reordered(NULL) +
    scale_y_continuous(
        paste(ifelse(wcs$stat1d == "ws", "scaled", ""),
            .stats1d_lab[wcs$stat1d]),
        limits = c(-0.1, 1), n.breaks = 3)

thm <- theme(
    legend.text.align = 0,
    legend.title = element_blank(),
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")