# wcs <- list(reftyp = "b", stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("plts/stat_1d_by_reftyp-mds,%s,%s.rds", wcs$reftyp, wcs$stat1d),
#     pdf = sprintf("plts/stat_1d_by_reftyp-mds,%s,%s.pdf", wcs$reftyp, wcs$stat1d))

source(args$fun)
res <- readRDS(args$res)

df <- res %>%
    # keep data of interest
    filter(
        reftyp == wcs$reftyp,
        stat1d == wcs$stat1d) %>%
    .filter_res() %>% 
    # average across groups
    group_by(refset, reftyp, method, metric, group) %>%
    .avg(n = 2)

mds <- df %>% 
    pivot_wider(
        id_cols = c(refset, method),
        names_from = metric, 
        values_from = stat) %>% 
    select(any_of(.metrics_lab)) %>%
    as.matrix() %>% t() %>% 
    dist() %>% cmdscale()

gg <- mds %>% 
    data.frame(rownames(.)) %>% 
    set_colnames(c("x", "y", "metric")) %>% 
    mutate(
        type = case_when(
            metric %in% .none_metrics ~ "global",
            grepl("gene", metric) ~ "gene",
            grepl("cell", metric) ~ "cell"),
        type = factor(type, c("gene", "cell", "global")),
        metric = .metrics_lab[metric])
            
plt <- ggplot(gg, aes(x, y, 
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
ggsave(args$pdf, fig, width = 9, height = 6, units = "cm")
