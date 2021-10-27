# args <- list(
#     pdf = "figs/mds.pdf",
#     uts = "code/utils-plotting.R",
#     rds = list.files("plts", "reftyp-mds.*ks\\.rds", full.names = TRUE))

source(args$uts)
ps <- lapply(args$rds, readRDS)
ps[[1]]$guides$fill <- "none"

fig <- wrap_plots(ps, ncol = 1) +
    plot_layout(guides = "collect") +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        legend.position = "bottom",
        plot.tag = element_text(size = 9, face = "bold"))

ggsave(args$pdf, fig, width = 9, height = 17, units = "cm")