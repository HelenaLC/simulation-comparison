suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
    library(tidyr)
})

df <- readRDS(args$res)
df$metrics <- with(df, paste(metric1, metric2, sep = " vs. "))

df <- df %>% 
    group_by(refset, method, group, metrics) %>% 
    summarize_at("stat", mean) %>% 
    ungroup() %>%
    complete(refset, method, group, metrics,
        fill = list(emd = NA))

p <- ggplot(df, 
    aes(method, metrics, fill = stat)) +
    facet_grid(group ~ refset) +
    geom_tile(color = "black", width = 1, height = 1) +
    scale_fill_viridis_c(limits = c(0, NA), na.value = "grey95") +
    coord_equal(expand = FALSE) +
    theme_linedraw(6) + theme(
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        panel.grid = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(color = "black"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.key.size = unit(0.5, "lines"))

ggsave(args$fig, p, width = 15, height = 6, units = "cm")
