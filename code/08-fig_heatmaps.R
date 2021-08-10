source(args$fun)

ps <- lapply(fns <- args$rds, readRDS)

# re-order by dimension & type
dim <- gsub(".*(1|2)d.*", "\\1", fns)
typ <- gsub(".*,(n|b|k|g),ks.*", "\\1", fns)
names(ps) <- paste0(typ, dim)
ps <- ps[paste0(
    c("n", "b", "k", "g"), 
    rep(c(1, 2), each = 4))]

ps[1:4] <- lapply(ps[1:4], \(.) {
    y <- .$data$metric
    y <- factor(y, .metrics_lab)
    .$data$metric <- y
    return(.)
})

# fix y-axis order across panels and add rectangles 
# highlighting gene-/cell-level & global summaries

s <- 0.50 # border size
d <- 0.00 # offset b/w boxes

ps[1:4] <- lapply(ps[1:4], \(.)
    . + scale_y_discrete(limits = rev(.metrics_lab)) +
        geom_rect(
            xmin = 0.5 + d, 
            xmax = length(unique(.$data$method)) + 0.5 - d, 
            ymax = length(.metrics_lab) + 0.5 - d, 
            ymin = length(.gene_metrics) + 0.5 + d, 
            size = s, fill = NA, col = "red") +
        geom_rect(
            xmin = 0.5 + d, 
            xmax = length(unique(.$data$method)) + 0.5 - d, 
            ymin = length(.none_metrics) + 0.5 + d,
            ymax = length(.gene_metrics) + 0.5 - d, 
            size = s, fill = NA, col = "blue") +
        geom_rect(
            xmin = 0.5 + d, 
            xmax = length(unique(.$data$method)) + 0.5 - d, 
            ymin = 0.5 - d, 
            ymax = length(.none_metrics) + 0.5 - d, 
            size = s, fill = NA, col = "green3"))

.metric_pairs <- unique(ps[[5]]$data$metrics)
.metric_pairs <- .metric_pairs[c(3, 2, 1, 7, 6, 5, 4)]
ps[5:8] <- lapply(ps[5:8], \(.) 
    . + scale_y_discrete(limits = rev(.metric_pairs)) +
        geom_rect(
            xmin = 0.5 - d, 
            xmax = length(unique(.$data$method)) + 0.5 - d, 
            ymax = length(.metric_pairs) + 0.5 - d, 
            ymin = 1.5 + d, 
            size = s, fill = NA, col = "red") +
        geom_rect(
            xmin = 0.5 - d, 
            xmax = length(unique(.$data$method)) + 0.5 - d, 
            ymin = 0.5 + d,
            ymax = 1.5 - d, 
            size = s, fill = NA, col = "blue"))

# drop y-axis labels from all but left-most panels
ps[-c(1, 5)] <- lapply(ps[-c(1, 5)], "+", 
    theme(axis.text.y = element_blank()))

# re-size relative to number of 
# rows (metrics) & columns (methods)
hs <- c(
    length(unique(ps[[1]]$data$metric)),
    1.5 + length(unique(ps[[5]]$data$metrics)))
ws <- sapply(ps[1:4], \(.) nlevels(.$data$method))

fig <- 
    wrap_plots(ps, nrow = 2, heights = hs, widths = ws) +
    plot_layout(guides = "collect") +
    plot_annotation(tag_levels = "a") &
    coord_cartesian() &
    theme(
        axis.text.x = element_text(angle = 30),
        plot.margin = margin(l = 2, unit = "mm"),
        plot.tag = element_text(face = "bold", size = 9))

ggsave(args$pdf, fig, width = 16, height = 10, units = "cm")
