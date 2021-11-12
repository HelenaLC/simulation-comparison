# args <- list(
#     uts = "code/utils-plotting.R",
#     pdf = "figs/summaries.pdf",
#     rds = file.path("plts", c(
#         "qc_ref-correlations.rds",
#         "stat_1d_by_stat1d-correlations,ks.rds",
#         "stat_1d_by_stat1d-mds,ks.rds",
#         "stat_1d_by_stat1d-pca,ks.rds")))

source(args$uts)
ps <- lapply(args$rds, readRDS)

ps[c(1, 2)] <- lapply(ps[c(1, 2)], "+", theme(
    axis.text.x = element_text(size = 3, angle = 30)))

ps[[3]]$layers[[2]]$aes_params$size <- 1.25
ps[[3]] <- ps[[3]] + theme(legend.position = "right")
ps[[3]] <- wrap_elements(full = ps[[3]])

ps[[4]][[1]] <- ps[[4]][[1]] +
    theme(legend.position = "none")
ps[[4]][[1]]$coordinates$expand <- TRUE
ps[[4]][[2]]$layers <- ps[[4]][[2]]$layers[-4]
ps[[4]][[2]] <- ps[[4]][[2]] +
    theme(
        legend.position = c(0.95, 0.5),
        legend.justification = c(1, 0.5))

ps[[4]] <- ps[[4]] & theme(plot.tag = element_blank())
ps[[4]] <- wrap_elements(full = ps[[4]])

fig <- (wrap_plots(ps[1:3], ncol = 1) |
    wrap_plots(ps[4], ncol = 1)) +
    plot_layout(widths = c(1, 2.5)) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(l = 1, t = 1, unit = "mm"),
        plot.tag = element_text(size = 9, face = "bold"))

ggsave(args$pdf, fig, width = 16, height = 12, units = "cm")
