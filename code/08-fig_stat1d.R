# args <- list(
#     uts = "code/utils-plotting.R",
#     pdf = "figs/stat1d.pdf",
#     rds = list.files("plts", "stat_1d_by_reftyp-boxplot.*\\.rds", full.names = TRUE))

source(args$uts)

ps <- lapply(c("n", "b", "k"), function(type) {
    pat <- sprintf(",%s,", type)
    fns <- grep(pat, args$rds, value = TRUE)
    lapply(rev(fns), readRDS) %>% 
        wrap_plots(ncol = 1) +
        plot_layout(guides = "collect") +
        plot_annotation(tag_levels = "a") &
        theme(
            panel.spacing = unit(1, unit = "mm"),
            plot.margin = margin(t = 1, unit = "mm"),
            plot.tag = element_text(size = 9, face = "bold"))
}) 

print.gglist <- \(p, ...) plyr::l_ply(p, print, ...)
fig <- structure(ps, class = c("gglist", "ggplot"))
ggsave(args$pdf, fig, width = 16, height = 16, units = "cm")
