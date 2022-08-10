# args <- list(
#     pdf = "figs/heatmaps.pdf",
#     uts = "code/utils-plotting.R",
#     rds = list.files("plts", "stat_(1|2)d_by_reftyp-heatmap.*ks2?\\.rds", full.names = TRUE))

source(args$uts)
ps <- lapply(fns <- args$rds, readRDS)

# re-order by dimension & type
dim <- gsub(".*(1|2)d.*", "\\1", fns)
typ <- gsub(".*,(n|b|k),ks.*", "\\1", fns)
names(ps) <- paste0(typ, dim)
ps <- ps[paste0(
    c("n", "b", "k"), 
    rep(c(1, 2), each = 3))]

# assure global metrics are 
# included across all panels

ps[1:3] <- lapply(ps[1:3], \(.) {
    y <- .$data$metric
    y <- factor(y, .metrics_lab)
    .$data$metric <- y
    return(.)
})

# fix y-axis order across panels and add rectangles 
# highlighting gene-/cell-level & global summaries

s <- 0.50 # border size
d <- 0.00 # offset b/w boxes

ps[1:3] <- lapply(ps[1:3], \(p)
    p + scale_y_discrete(limits = rev(.metrics_lab)) +
        geom_rect(
            xmin = 0.5 + d, 
            xmax = length(unique(p$data$method)) + 0.5 - d, 
            ymax = length(.metrics_lab) + 0.5 - d, 
            ymin = length(.none_metrics) + length(.cell_metrics) + 0.5 + d, 
            size = s, fill = NA, col = "red") +
        geom_rect(
            xmin = 0.5 + d, 
            xmax = length(unique(p$data$method)) + 0.5 - d, 
            ymin = length(.none_metrics) + 0.5 + d,
            ymax = length(.none_metrics) + length(.cell_metrics) + 0.5 - d, 
            size = s, fill = NA, col = "blue") +
        geom_rect(
            xmin = 0.5 + d, 
            xmax = length(unique(p$data$method)) + 0.5 - d, 
            ymin = 0.5 - d, 
            ymax = length(.none_metrics) + 0.5 - d, 
            size = s, fill = NA, col = "green3"))

# get x-axis (methods) ordering
xo <- lapply(ps[1:3], \(p) ggplot_build(p)$layout$panel_scales_x[[1]]$limits)

.metric_pairs <- unique(ps[[5]]$data$metrics)
.metric_pairs <- .metric_pairs[c(3, 2, 1, 9, 8, 6, 5, 4, 7)]

ps[4:6] <- lapply(seq_along(ps[4:6]), \(i) {
    p <- ps[4:6][[i]]
    p + scale_x_discrete(limits = xo[[i]]) +
        scale_y_discrete(limits = rev(.metric_pairs)) +
        geom_rect(
            xmin = 0.5 - d, 
            xmax = length(unique(p$data$method)) + 0.5 - d, 
            ymax = length(.metric_pairs) + 0.5 - d, 
            ymin = 3.5 + d, 
            size = s, fill = NA, col = "red") +
        geom_rect(
            xmin = 0.5 - d, 
            xmax = length(unique(p$data$method)) + 0.5 - d, 
            ymin = 0.5 + d,
            ymax = 3.5 - d, 
            size = s, fill = NA, col = "blue")
})

# drop y-axis labels from all but left-most panels
ps[-c(1, 4)] <- lapply(ps[-c(1, 4)], "+", 
    theme(axis.text.y = element_blank()))

# re-size relative to number of 
# rows (metrics) & columns (methods)
hs <- c(
    length(unique(ps[[1]]$data$metric)),
    1.5 + length(unique(ps[[5]]$data$metrics)))
ws <- sapply(ps[1:3], \(.) nlevels(.$data$method))

x <- c("gene-level" = "red", "cell-level" = "blue", "global" = "green3")
ps[[1]] <- ps[[1]] +
    geom_point(
        inherit.aes = FALSE,
        data = data.frame(x), 
        aes_string(
            ps[[1]]$data$method[1], 
            ps[[1]]$data$metric[1], 
            col = "x"), alpha = 0) +
    scale_color_manual("type of\nsummary", values = x) +
    guides(color = guide_legend(order = 1, override.aes = list(alpha = 1))) 

fig <- wrap_plots(ps,
    nrow = 2, heights = hs, widths = ws) +
    plot_layout(guides = "collect") +
    plot_annotation(tag_levels = "a") &
    coord_cartesian() &
    theme(
        axis.text.x = element_text(angle = 30),
        plot.margin = margin(l = 2, unit = "mm"),
        plot.tag = element_text(face = "bold", size = 9))

ggsave(args$pdf, fig, width = 16, height = 12, units = "cm")
