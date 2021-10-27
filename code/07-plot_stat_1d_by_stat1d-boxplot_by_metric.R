# wcs <- list(stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     rds = "plts/stat_1d_by_reftyp-boxplot.rds",
#     pdf = "plts/stat_1d_by_reftyp-boxplot.pdf",
#     res = list.files("outs", paste0("^stat_1d.*", wcs$stat1d, "\\."), full.names = TRUE))
# args$res <- sample(args$res, 100)

source(args$fun)
res <- readRDS(args$res)

df <- res %>%
    # keep data of interest
    filter(stat1d == wcs$stat1d) %>% 
    .filter_res() %>% 
    # average across groups
    group_by(refset, method, metric, group) %>% .avg(n = 1)

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
    scale_y_continuous(limits = c(-0.1, NA), n.breaks = 3) +
    labs(x = NULL, y = .stats1d_lab[wcs$stat1d])

thm <- theme(
    legend.text.align = 0,
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")
