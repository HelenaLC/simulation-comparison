source("scripts/utils-plotting.R")

p1 <- readRDS("plots/stat_1d-boxplot_by_metric,ks.rds")
p2 <- readRDS("plots/stat_1d-boxplot_by_method,ks.rds")

p1 <- p1 + theme(plot.margin = margin(0,0,1,0,"mm"))
p2 <- p2 + theme(plot.margin = margin(1,0,0,0,"mm"))

p1$facet$params$free$y <- FALSE
p2$facet$params$free$y <- FALSE

suppressMessages({
    fig <- wrap_plots(p1, p2, ncol = 1, heights = c(2, 3)) +
        plot_annotation(tag_levels = "a") &
        scale_y_continuous(
            "KS statistic", 
            limits = c(0, 1), 
            n.breaks = 3) &
        theme(
            panel.spacing = unit(1, "mm"),
            plot.margin = margin(1,0,1,0,"mm"),
            plot.tag = element_text(face = "bold", size = 9))
})

fnm <- "boxplots.pdf"
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 16, height = 12, units = "cm")
