# wcs <- list(stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("plts/stat_1d_by_stat1d-correlations_by_metric,%s.rds", wcs$stat1d),
#     pdf = sprintf("plts/stat_1d_by_stat1d-correlations_by_metric,%s.pdf", wcs$stat1d))

source(args$fun)
res <- readRDS(args$res)

mat <- res %>% 
    # keep method of interest
    filter(stat1d == wcs$stat1d) %>% 
    .filter_res() %>% 
    # for each method, method & summary, average across groups & refsets
    group_by(refset, method, metric, group) %>% .avg(n = 1) %>% 
    # for each method, correlate b/w summaries & across refsets
    split(.$metric) %>% 
    lapply(\(.)
        pivot_wider(.,
            names_from = method, 
            values_from = stat) %>% 
        select(any_of(names(.methods_pal))) %>% 
        cor(method = "spearman", 
            use = "pairwise.complete.obs"))

df <- lapply(mat, \(u) u %>% 
    data.frame(from = rownames(.)) %>% 
    pivot_longer(-from, names_to = "to")) %>% 
    bind_rows(.id = "metric") %>% 
    complete(from, to, metric, fill = list(value = NA))
    
foo <- df %>% 
    group_by(from, to) %>% 
    summarise(value = mean(value), .groups = "drop") %>% 
    pivot_wider(names_from = to, values_from = value) %>% 
    select(-from) %>% 
    as.matrix()
foo[is.na(foo)] <- 1
o <- colnames(foo)[hclust(dist(foo))$order]

plt <- ggplot(df, aes(from, to, fill = value)) +
    facet_wrap(~ metric, nrow = 2) +
    scale_fill_distiller(
        bquote("r("*.(.stats1d_lab[wcs$stat1d])*")"),
        palette = "RdYlBu", 
        na.value = "grey",
        limits = c(-1, 1), 
        n.breaks = 3) +
    scale_x_discrete(limits = rev(o), labels = names(.methods_pal)) +
    scale_y_discrete(limits = o, labels = names(.methods_pal)) +
    coord_equal(expand = FALSE) +
    geom_tile()

thm <- theme(
    axis.title = element_blank(),
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 24, height = 8.5, units = "cm")

