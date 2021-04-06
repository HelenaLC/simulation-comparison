suppressPackageStartupMessages(library(ggplot2))

df <- readRDS(args$res)

p <- ggplot(df, aes(type.metric, stat, fill = group, col = group)) +
    facet_wrap(~ method) + 
    geom_boxplot(size = 0.25, outlier.size = 0.5,
        width = 0.75, alpha = 0.5, key_glyph = "point") +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    guides(fill = guide_legend(override.aes = list(alpha = 1, size = 2))) +
    theme_linedraw(6) + theme(
        aspect.ratio = 0.5, 
        axis.title = element_blank(),
        panel.grid = element_line(color = "grey"),
        panel.grid.minor = element_blank(),
        legend.key.size = unit(0.5, "lines"),
        strip.background = element_blank(),
        strip.text = element_text(color = "black"),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(args$fig, p, width = 15, height = 9, units = "cm")
