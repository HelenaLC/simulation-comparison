# args <- list(
#     uts = "code/utils-plotting.R",
#     rds = c(
#         "plts/stat_1d_by_stat1d-boxplot_by_metric,ks.rds",
#         "plts/stat_1d_by_stat1d-boxplot_by_method,ks.rds"),
#     pdf = "figs/boxplots.pdf")

source(args$uts)

ps <- lapply(args$rds, readRDS)

fig <- wrap_plots(ps, ncol = 1, heights = c(3, 4)) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        panel.spacing = unit(1, "mm"),
        plot.tag = element_text(face = "bold", size = 9))

ggsave(args$pdf, fig, width = 16, height = 14, units = "cm")
