# args <- list(
#     rds = list.files("plts", "rts.*\\.rds", full.names = TRUE),
#     pdf = "figs/runtimes.pdf",
#     uts = "code/utils-plotting.R")

source(args$uts)

ps <- lapply(args$rds, readRDS)

pat <- paste0("_", c("n", "b", "k"), ".rds")
ps <- ps[sapply(pat, grep, args$rds)]

fig <- wrap_plots(ps, ncol = 1) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        panel.spacing = unit(1, "mm"),
        legend.title = element_blank(),
        plot.tag = element_text(size = 9, face = "bold"))

ggsave(args$pdf, fig, width = 18, height = 21, units = "cm")
