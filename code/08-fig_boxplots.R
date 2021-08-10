# args <- list(
#     fun = "code/utils.R",
#     rds = c(
#         "plts/stat_1d_by_stat1d-boxplot_by_metric,ks.rds",
#         "plts/stat_1d_by_stat1d-boxplot_by_method,ks.rds"),
#     pdf = "figs/boxplots.pdf")

source(args$fun)

ps <- lapply(args$rds, readRDS)
ps[[1]]$guides$fill$ncol <- 2

fig <- wrap_plots(ps, ncol = 1, heights = c(2, 3)) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        plot.tag = element_text(face = "bold", size = 9))

ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")
