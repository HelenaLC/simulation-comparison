# args <- list(
#     fun = "code/utils.R",
#     pdf = "figs/scatters.pdf",
#     rds = list.files("plts", "scatters.*\\.rds", full.names = TRUE))

source(args$fun)

ps <- lapply(args$rds, readRDS)

fig <- 
    wrap_plots(ps, ncol = 1, heights = c(3, 1)) +
    plot_annotation(tag_levels = "a") &
    scale_x_sqrt(breaks = c(0.2, 0.5, 1)) &
    theme(
        plot.margin = margin(r = 1, unit = "mm"),
        plot.tag = element_text(size = 9, face = "bold"))

ggsave(args$pdf, fig, width = 16, height = 11, units = "cm")