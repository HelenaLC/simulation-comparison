source("scripts/utils-plotting.R")

for (type in c("n", "b", "k", "g")) {
    
p1 <- readRDS(sprintf("plots/stat_1d_by_reftyp-boxplot,%s,ks.rds", type))
p2 <- readRDS(sprintf("plots/stat_1d_by_reftyp-boxplot,%s,ws.rds", type))

p1 <- p1 + scale_y_continuous("KS statistics", limits = c(0, 1), n.breaks = 3)
p2 <- p2 + scale_y_continuous("Wasserstein metric", limits = c(0, NA), n.breaks = 4) 
    
ncol <- ifelse(type == "n", 4, 5)
p1 <- p1 + facet_wrap(~ metric, ncol = ncol, scales = "free_x")
p2 <- p2 + facet_wrap(~ metric, ncol = ncol, scales = "free")

suppressMessages({
    fig <- wrap_plots(p1, p2, ncol = 1) +
        plot_annotation(tag_levels = "a") +
        plot_layout(guides = "collect") &
        theme(
            panel.spacing = unit(1, "mm"),
            plot.margin = margin(1,0,1,0,"mm"),
            plot.tag = element_text(face = "bold", size = 9))
})

fnm <- sprintf("stat_1d_by_reftyp-boxplot,%s.pdf", type)
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 16, height = 8, units = "cm")

}