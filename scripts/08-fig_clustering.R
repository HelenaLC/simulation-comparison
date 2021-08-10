source("scripts/utils-plotting.R")

ps <- c(
    "plots/clustering-boxplot_by_simulator_F1.rds",
    "plots/clustering-boxplot_dF1.rds",
    "plots/clustering-heatmap_by_simulator.rds",
    "plots/clustering-heatmap_corr.rds") %>%
    lapply(readRDS)

n <- length(unique(ps[[1]]$data$clustering_method))
pal <- brewer.pal(n, "Set2")

p1 <- ps[[1]] + 
    scale_fill_manual(values = pal) +
    scale_color_manual(values = pal) 
p2 <- ps[[2]] + theme(aspect.ratio = 1)
p3 <- ps[[3]] + theme(
    axis.text.x = element_text(size = 3),
    axis.text.y = element_text(size = 3))
p4 <- ps[[4]] 

fig <- 
    # (wrap_elements(full = p1) + p2) / 
    # (p3 + wrap_elements(full = p4)) + 
    (wrap_elements(plot = p1) + p2) /
    (p3 + p4) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        plot.tag = element_text(face = "bold", size = 9))

fn <- "clustering.pdf"
fn <- file.path("figures", fn)
ggsave(fn, fig, width = 16, height = 8, units = "cm")