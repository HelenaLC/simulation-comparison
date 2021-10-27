# wcs <- list(reftyp = "k", stat1d = "ks")
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
    # for each method & summary, 
    # average across groups & refsets
    group_by(metric, method, refset, group) %>% .avg(n = 3) %>% 
    complete(method, metric, fill = list(stat = NA))

# order methods by average across metrics
ox <- df %>% 
    group_by(method) %>% 
    summarise_at("stat", mean, na.rm = TRUE) %>% 
    arrange(desc(stat)) %>% 
    pull("method")

# order metrics by average across methods
oy <- df %>% 
    group_by(metric) %>% 
    summarise_at("stat", mean, na.rm = TRUE) %>% 
    arrange(desc(stat)) %>% 
    pull("metric")

plt <- ggplot(df, 
    aes(method, metric, fill = stat)) +
    geom_tile(col = "white") + 
    scale_fill_distiller(
        .stats1d_lab[wcs$stat1d],
        palette = "RdYlBu",
        na.value = "grey",
        limits = c(0, 1),
        breaks = c(0, 1)) +
    coord_equal(expand = FALSE) +
    scale_x_discrete(limits = rev(ox)) + 
    scale_y_discrete(limits = rev(oy))

thm <- theme(
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 8, height = 6, units = "cm")