# val <- "cms"
# args <- list(
#     fun = "code/utils.R",
#     pdf = "figs/integration.pdf",
#     rds = sprintf(c(
#         "plts/batch-boxplot_by_method_%s.rds",
#         "plts/batch-boxplot_dX_%s.rds",
#         "plts/batch-heatmap_by_method_%s.rds",
#         "plts/batch-correlations_%s.rds"), val))

source(args$fun)

ps <- lapply(args$rds, readRDS)

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
