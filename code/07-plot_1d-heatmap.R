suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

df <- readRDS(args$res)
df <- mutate(df, metric = paste0(type, "_", metric))

p <- df %>% 
  group_by(refset, group, method, metric) %>%
  summarize_at("stat", mean) %>% 
  ungroup() %>%
  complete(method, refset, group, metric,
    fill = list(stat = NA)) %>% 
  ggplot(aes(method, metric, fill = stat)) +
  facet_grid(group ~ refset) + 
  geom_tile(col = "black") +
  scale_fill_viridis_c(na.value = "grey95") +
  coord_equal(expand = FALSE) +
  theme_linedraw(6) + theme(
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    strip.background = element_blank(),
    strip.text = element_text(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.key.size = unit(0.5, "lines"))

ggsave(args$fig, p, width = 15, height = 8, units = "cm")