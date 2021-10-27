# wcs <- list(stat2d = "emd", reftyp = "n")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_2d.rds",
#     rds = "plts/stat_2d_by_reftyp-boxplot,b,ks2.rds",
#     pdf = "plts/stat_2d_by_reftyp-boxplot,b,ks2.pdf")

source(args$fun)
res <- .read_res(args$res)
    
df <- res %>% 
    mutate(metrics = paste(metric1, metric2, sep = "\n")) %>% 
    # keep statistic of interest
    filter(stat2d == wcs$stat2d) %>% 
    # keep group-level comparisons only
    { if (wcs$reftyp == "n") . else
        mutate(., across(
            c(group, id), 
            as.character)) %>% 
        filter(group != id) } %>% 
    # scale values b/w 0 and 1 for visualization
    group_by(metrics) %>% 
    mutate(stat = stat/max(stat, na.rm = TRUE))

pal <- .methods_pal[levels(df$method)]
lab <- parse(text = paste(
    sep = "~",
    sprintf("bold(%s)", LETTERS), 
    gsub("\\s", "~", names(pal))))

anno <- df %>% 
    group_by(method, metrics) %>% 
    summarize_at("stat", median) %>% 
    mutate(letter = LETTERS[match(method, levels(method))])

plt <- ggplot(df, aes(
    reorder_within(method, stat, metrics, median), 
    stat, col = method, fill = method)) +
    facet_wrap(~ metrics, nrow = 3, scales = "free_x") +
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
        paste(ifelse(wcs$stat2d == "emd", "scaled", ""),
            .stats2d_lab[wcs$stat2d]),
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
