# wcs <- list(stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("plts/stat_1d_by_stat1d-mds,%s.rds", wcs$stat1d),
#     pdf = sprintf("plts/stat_1d_by_stat1d-mds,%s.pdf", wcs$stat1d))

source(args$fun)
res <- readRDS(args$res)

df <- res %>%
    # keep data of interest
    filter(stat1d == wcs$stat1d) %>%
    .filter_res() %>% 
    # average across groups & refsets
    group_by(method, metric, refset, group) %>%
    .avg(n = 3) %>%
    pivot_wider(
        names_from = metric, 
        values_from = stat) %>% 
    rowwise() %>% 
    drop_na(any_of(.metrics_lab)) %>% 
    select(any_of(.metrics_lab)) %>% 
    as.matrix() %>% 
    t() %>% 
    dist() %>% 
    cmdscale() %>% 
    data.frame(rownames(.)) %>% 
    set_colnames(c("x", "y", "metric")) %>% 
    mutate(
        type = case_when(
            metric %in% .none_metrics ~ "global",
            grepl("gene", metric) ~ "gene",
            grepl("cell", metric) ~ "cell"),
        metric = .metrics_lab[metric])
            
plt <- ggplot(df, aes(x, y, 
    col = type, fill = type, label = metric)) +
    geom_point(size = 2, shape = 21, col = "black", alpha = 0.5) +
    geom_text_repel(size = 2, show.legend = FALSE) +
    scale_fill_manual(values = c("red", "blue", "green3")) +
    scale_color_manual(values = c("red", "blue", "green3")) +
    scale_x_continuous(expand = expansion(mult = 0.1)) +
    scale_y_continuous(expand = expansion(mult = 0.1)) +
    labs(x = "MDS dim. 1", y = "MDS dim. 2") +
    coord_fixed()

thm <- theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    panel.grid.major = element_line(color = "grey"))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 12, height = 8, units = "cm")
