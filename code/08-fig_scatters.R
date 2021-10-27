# args <- list(
#     uts = "code/utils-plotting.R",
#     pdf = "figs/scatters.pdf",
#     rds = list.files("plts", "scatters.*\\.rds", full.names = TRUE))

source(args$uts)

ps <- lapply(args$rds, readRDS)
ps[[1]]$facet$params$nrow <- 2
ps[[2]]$facet$params$nrow <- 1

fig <- 
    wrap_plots(ps, ncol = 1, heights = c(2, 1)) +
    plot_annotation(tag_levels = "a") &
    scale_x_sqrt(breaks = c(0.2, 0.5, 1)) &
    theme(
        plot.margin = margin(r = 1, unit = "mm"),
        plot.tag = element_text(size = 9, face = "bold"))

ggsave(args$pdf, fig, width = 20, height = 11, units = "cm")
