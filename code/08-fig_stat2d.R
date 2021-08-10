# args <- list(
#     fun = "code/utils.R",
#     pdf = "figs/stat2d.pdf",
#     rds = list.files("plts", "stat_2d_by_reftyp-boxplot.*\\.rds", full.names = TRUE))

source(args$fun)

pdf(args$fig, width = 18/2.54, height = 9/2.54)

ps <- lapply(c("n", "b", "k", "g"), function(type) {
    pat <- sprintf(",%s,", type)
    fns <- grep(pat, args$rds, value = TRUE)
    lapply(rev(fns), readRDS) %>%
        wrap_plots(ncol = 1) +
        plot_layout(guides = "collect") +
        plot_annotation(tag_levels = "a") &
        theme(
            panel.spacing = unit(1, "mm"),
            plot.margin = margin(1,0,1,0,"mm"),
            strip.text = element_text(size = 4),
            plot.tag = element_text(size = 9, face = "bold"))

})

print.gglist <- \(p, ...) plyr::l_ply(p, print, ...)
fig <- structure(ps, class = c("gglist", "ggplot"))
ggsave(args$pdf, fig, width = 18, height = 7, units = "cm")