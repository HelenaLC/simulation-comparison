# wcs <- list(stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("plts/stat_1d_by_stat1d-pca,%s.rds", wcs$stat1d),
#     pdf = sprintf("plts/stat_1d_by_stat1d-pca,%s.pdf", wcs$stat1d))

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
    drop_na(any_of(.metrics_lab))

# do PCA
pc <- df %>% 
    select(any_of(.metrics_lab)) %>%
    as.matrix() %>% prcomp()

# get coordinates
xy <- pc$x %>% 
    data.frame() %>%
    # add metadata
    mutate(
        select(df, !any_of(.metrics_lab)),
        method = droplevels(method))

# get loadings
rot <- pc$rotation %>% 
    data.frame() %>% 
    mutate(
        metric = .metrics_lab[rownames(.)],
        metric = factor(metric, metric))
ij <- c("PC1", "PC2")
m1 <- max(abs(xy[, ij]))
m2 <- max(abs(rot[, ij]))
rot[, ij] <- 0.5*rot[, ij]*m1/m2

# get percentages
var <- prop.table(pc$sdev^2)
var_lab <- round(100*var, 1)

p0 <- ggplot(xy, aes(PC1, PC2)) +
    geom_vline(xintercept = 0, size = 0.1) +
    geom_hline(yintercept = 0, size = 0.1) +
    coord_fixed() + labs(
        x = sprintf("PC1 (%s%%)", var_lab[1]),
        y = sprintf("PC2 (%s%%)", var_lab[2])) +
    scale_x_continuous(
        limits = range(xy$PC1), 
        expand = expansion(mult = 0.2)) +
    scale_y_continuous(
        limits = range(xy$PC2),
        expand = expansion(mult = 0.2))

p1 <- p0 +
    geom_point(
        aes(fill = method), shape = 21,
        size = 3, stroke = 0, alpha = 0.8) +
    geom_label_repel(
        aes(label = method, col = method),
        label.padding = unit(0.75, "mm"),
        size = 2, fontface = "bold", show.legend = FALSE) +
    scale_fill_manual(values = .methods_pal[levels(xy$method)]) +
    scale_color_manual(values = .methods_pal[levels(xy$method)]) 
    
p2 <- p0 +
    geom_segment(data = rot, 
        aes(0, 0, xend = PC1, yend = PC2, col = metric),
        size = 0.5, arrow = arrow(length = unit(1, "mm"))) +
    geom_label_repel(data = rot,
        aes(label = metric, col = metric), 
        label.padding = unit(0.75, "mm"),
        size = 2, fontface = "bold", show.legend = FALSE) +
    scale_color_manual(values = .metrics_pal[levels(rot$metric)]) 

thm <- theme(
    legend.justification = c(0, 0.5),
    panel.grid.major = element_line(size = 0.1, color = "grey"))

f1 <- .prettify(p1, thm)
f2 <- .prettify(p2, thm)
f2$guides$colour$override.aes$size <- 0.5

fig <- f1 / f2 +
    plot_annotation(tag_levels = "a") &
    theme(plot.tag = element_text(size = 9, face = "bold"))

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 18, units = "cm")
