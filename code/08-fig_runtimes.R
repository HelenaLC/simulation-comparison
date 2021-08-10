# args <- list(
#     rds = list.files("plts", "rts.*\\.rds", full.names = TRUE),
#     pdf = "figs/runtimes.pdf",
#     fun = "code/utils.R")

source(args$fun)

ps <- lapply(args$rds, readRDS)

pat <- paste0("_", c("n", "b", "k", "g"), ".rds")
ps <- ps[sapply(pat, grep, args$rds)]

fig <- wrap_plots(ps, ncol = 1) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        plot.tag = element_text(size = 9, face = "bold"))

ggsave(args$pdf, fig, width = 16, height = 16, units = "cm")