# wcs <- list(stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("plts/stat_1d_by_stat1d-boxplot,%s.rds", wcs$stat1d),
#     pdf = sprintf("plts/stat_1d_by_stat1d-boxplot,%s.pdf", wcs$stat2d))

source(args$fun)
res <- readRDS(args$res)

df <- res %>% 
    # keep data of interest
    filter(stat1d == wcs$stat1d) %>% 
    .filter_res() %>% 
    # average across groups
    group_by(refset, method, metric) %>% 
    .avg(n = 1)

# average statistics across refsets & summaries 
# statistic across all summaries
o <- df %>% 
    group_by(method, refset, metric) %>%
    .avg(n = 3) %>% 
    # order methods (panels) by average 
    arrange(stat) %>% 
    pull("method")
df <- df %>% mutate_at("method", factor, o)

pal <- .metrics_pal[levels(df$metric)]
lab <- parse(text = paste(
    sep = "~",
    sprintf("bold(%s)", LETTERS), 
    gsub("\\s", "~", names(pal))))

anno <- df %>% 
    group_by(method, metric) %>% 
    summarize_at("stat", median) %>% 
    mutate(letter = LETTERS[match(metric, levels(metric))])

plt <- ggplot(df, aes(
    reorder_within(metric, stat, method, median), 
    stat, col = metric, fill = metric)) +
    facet_wrap(~ method, nrow = 4, scales = "free_x") +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    geom_text(data = anno, 
        size = 1.5, color = "black", 
        aes(label = letter, y = -0.075)) + 
    scale_fill_manual(values = pal, labels = lab) +
    scale_color_manual(values = pal, labels = lab) +
    scale_y_continuous(limits = c(-0.1, NA), n.breaks = 3) +
    labs(x = NULL, y = .stats1d_lab[wcs$stat1d])

thm <- theme(
    legend.text.align = 0,
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")
