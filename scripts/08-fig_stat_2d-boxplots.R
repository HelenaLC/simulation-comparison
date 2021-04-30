source("scripts/utils-plotting.R")

for (type in c("n", "b", "k", "g")) {
    
p1 <- readRDS(sprintf("plots/stat_2d_by_reftyp-boxplot,%s,ks2.rds", type))
p2 <- readRDS(sprintf("plots/stat_2d_by_reftyp-boxplot,%s,emd.rds", type))

suppressMessages({
    fig <- wrap_plots(p1, p2, ncol = 1) +
        plot_annotation(tag_levels = "a") +
        plot_layout(guides = "collect") &
        theme(
            panel.spacing = unit(1, "mm"),
            plot.margin = margin(1,0,1,0,"mm"),
            plot.tag = element_text(face = "bold", size = 9))
})

fnm <- sprintf("stat_2d_by_reftyp-boxplot,%s.pdf", type)
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 18, height = 8, units = "cm")

}