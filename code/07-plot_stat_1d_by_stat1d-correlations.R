# wcs <- list(stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("plts/stat_1d_by_stat1d-correlations,%s.rds", wcs$stat1d),
#     pdf = sprintf("plts/stat_1d_by_stat1d-correlations,%s.pdf", wcs$stat1d))

source(args$fun)
res <- readRDS(args$res)

mat <- res %>% 
    # keep data of interest
    filter(stat1d == wcs$stat1d) %>% 
    .filter_res() %>% 
    # average across groups & subsets
    group_by(method, metric, refset, group) %>% 
    .avg(n = 3) %>% 
    # correlate b/w summaries, across methods & refsets
    pivot_wider(
        names_from = metric, 
        values_from = stat) %>% 
    select(any_of(.metrics_lab)) %>% 
    cor(method = "spearman", 
        use = "pairwise.complete.obs")

foo <- mat
foo[is.na(foo)] <- 1
xo <- rownames(mat)[hclust(dist(foo))$order]
yo <- rownames(mat)[hclust(dist(t(foo)))$order]

df <- mat %>% 
    data.frame(from = rownames(.)) %>% 
    pivot_longer(-from, names_to = "to") %>% 
    complete(from, to, fill = list(value = NA))
    
plt <- ggplot(df, aes(from, to, fill = value)) +
    geom_tile() +
    scale_fill_distiller(
        bquote("r("*.(.stats1d_lab[wcs$stat1d])*")"),
        palette = "RdYlBu",
        limits = c(-1, 1),
        n.breaks = 3) +
    coord_equal(expand = FALSE) +
    scale_x_discrete(limits = rev(xo), labels = .metrics_lab) +
    scale_y_discrete(limits = yo, labels = .metrics_lab)

thm <- theme(
    axis.title = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 9, height = 7.5, units = "cm")
