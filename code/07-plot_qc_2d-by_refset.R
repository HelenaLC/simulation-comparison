suppressPackageStartupMessages({
    library(ggplot2)
})

# wcs <- list(
#     type = "gene",
#     metric1 = "avg",
#     metric2 = "var")
# 
# args <- list(
#     x_ref = "results/qc_ref-panc8.indrop_alpha,gene_avg.rds",
#     y_ref = "results/qc_ref-panc8.indrop_alpha,gene_var.rds",
#     x_sim = list.files("results", "qc_sim-panc8.indrop_alpha,gene_avg.*", full.names = TRUE),
#     y_sim = list.files("results", "qc_sim-panc8.indrop_alpha,gene_var.*", full.names = TRUE))

x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)

df <- x %>% 
    rename(x = value) %>% 
    mutate(y = y$value)

p <- ggplot(df, aes(x, y)) +
    facet_grid(group.id ~ method) +
    stat_density_2d(
        geom = "raster", contour = FALSE, 
        aes(fill = after_stat(ndensity))) +
    scale_fill_distiller("normalized\ndensity", 
        palette = "BuPu", direction = 1, trans = "sqrt", 
        limits = c(0, 1), breaks = seq(0, 1, 0.5)) +
    labs(
        x = paste(wcs$type, wcs$metric1, sep = "."), 
        y = paste(wcs$type, wcs$metric2, sep = ".")) +
    theme_linedraw(6) +
    theme(
        aspect.ratio = 1,
        panel.grid = element_blank(),
        strip.text = element_text(color = "black"),
        strip.background = element_rect(fill = NA),
        legend.key.size = unit(0.75, "lines"))

ggsave(args$fig, p, width = 15, height = 15, units = "cm")
