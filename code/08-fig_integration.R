# val <- rep(c("cms", "ldf", "bcs"), each = 4)
# args <- list(
#     uts = "code/utils-plotting.R",
#     pdf = "figs/integration.pdf",
#     rds = sprintf(c(
#         "plts/batch-boxplot_by_method_%s.rds",
#         "plts/batch-boxplot_dX_%s.rds",
#         "plts/batch-heatmap_by_method_%s.rds",
#         "plts/batch-correlations_%s.rds"), val))

source(args$uts)
ps <- lapply(args$rds, readRDS)

# split plots by value
pat <- ".*_(.*)\\.rds$"
lys <- split(ps, gsub(pat, "\\1", args$rds))

# fix methods order according to ref-sim 
# difference for boxplots & heatmaps
o <- c("ref", ggplot_build(lys[[1]][[2]])$layout$panel_params[[1]]$x$breaks)
lys <- lapply(lys, \(ps) {
    ps[[1]]$data$sim_method <- factor(ps[[1]]$data$sim_method, o)
    ps[[3]]$data$sim_method <- factor(ps[[3]]$data$sim_method, o)
    return(ps)
})

# generate separate figure for each
lys <- lapply(lys, \(p) {
    p[[3]]$layers[[1]]$aes_params$colour <- NA
    p[[3]] <- p[[3]] + theme(
        axis.text.y = element_text(size = 3, angle = 60, hjust = 1),
        axis.text.x = element_text(size = 3, angle = 90, vjust = 0.5))
    p[[4]] <- p[[4]] + theme(
        legend.background = element_blank())
    p <- lapply(p, \(.) wrap_elements(full = .))
    ws <- c(3, 1)
    fig <- ((p[[1]] + p[[2]]) + plot_layout(widths = ws)) / 
    ((p[[3]] + p[[4]]) + plot_layout(widths = ws)) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        plot.tag = element_text(face = "bold", size = 9))
})

pdf(args$pdf, width = 17.6/2.54, height = 9.9/2.54)
for (p in lys) print(p); dev.off()
