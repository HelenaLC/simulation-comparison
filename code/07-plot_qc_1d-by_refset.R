suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
})

# args <- list(
#     ref = list.files("results", "qc_ref-CellBench", full.names = TRUE),
#     sim = list.files("results", "qc_sim-CellBench", full.names = TRUE))

ref <- args$ref %>%
    lapply(readRDS) %>%
    bind_rows() %>%
    pivot_longer(matches("gene|cell_")) %>%
    filter(!is.na(value))

sim <- args$sim %>%
    lapply(readRDS) %>%
    bind_rows() %>%
    pivot_longer(matches("^gene|cell_")) %>%
    filter(!is.na(value))

df <- bind_rows(ref, sim) %>%
    mutate(group_id = paste(group, id, sep = "_"))

p <- ggplot(df, 
    aes(method, value, col = method, fill = method)) +
    facet_grid(name ~ group_id, scales = "free") +
    geom_violin(key_glyph = "point", width = 1, size = 0.25, alpha = 0.5) +
    geom_boxplot(
        col = "black", fill = NA,
        size = 0.125, outlier.size = 0.125,
        width = 0.25, show.legend = FALSE) +
    scale_fill_manual(NULL, values = .pal) +
    scale_color_manual(NULL, values = .pal) +
    guides(col = guide_legend(override.aes = list(size = 2, alpha = 1))) +
    theme_linedraw(6) +
    theme(
        axis.title = element_blank(),
        panel.grid = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(color = "black"),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        legend.position = "bottom",
        legend.key.size = unit(0.5, "lines"))

ggsave(args$fig, p, width = 15, height = 15, units = "cm")
