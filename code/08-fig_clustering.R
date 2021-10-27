# args <- list(
#     rds = file.path("plts", c(
#         "clust-boxplot_by_method.rds",
#         "clust-boxplot_dF1.rds",
#         "clust-heatmap_by_method.rds",
#         "clust-correlations.rds")),
#     uts = "code/utils-plotting.R",
#     pdf = "figs/clustering.pdf")

source(args$uts)

ps <- lapply(args$rds, readRDS)

# fix methods order according to ref-sim 
# difference for boxplots & heatmaps
o <- c("ref", ggplot_build(ps[[2]])$layout$panel_params[[1]]$x$breaks)
ps[[1]]$data$sim_method <- factor(ps[[1]]$data$sim_method, o)
ps[[3]]$data$sim_method <- factor(ps[[3]]$data$sim_method, o)

ps[[3]]$layers[[1]]$aes_params$colour <- NA

ps[[3]] <- ps[[3]] + theme(
    axis.text.y = element_text(size = 3, angle = 60, hjust = 1),
    axis.text.x = element_text(size = 3, angle = 90, vjust = 0.5))

ps[[4]] <- ps[[4]] + theme(
    legend.background = element_blank())

ps <- lapply(ps, \(.) wrap_elements(full = .))

ws <- c(3, 1)

fig <- 
    ((ps[[1]] + ps[[2]]) + plot_layout(widths = ws)) / 
    ((ps[[3]] + ps[[4]]) + plot_layout(widths = ws)) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        plot.tag = element_text(face = "bold", size = 9))

ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")
