suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

df <- readRDS(args$res)
df <- mutate(df, type_metric = paste0(type, "_", metric))

p <- df %>% 
  group_by(refset, group, method, type_metric) %>%
  summarize_at("stat", mean) %>% 
  ungroup() %>%
  tidyr::complete(method, refset, group, type_metric,
                  fill = list(stat = NA)) %>% 
  ggplot(aes(method, type_metric, fill = 1-stat)) +
  facet_grid(group ~ refset) + 
  geom_tile(col = "black") +
  scale_fill_distiller(
    "1-KS", limits = c(0, 1),
    palette = "RdYlBu", na.value = "grey95") +
  coord_equal(2/3, expand = FALSE) +
  theme_linedraw(6) + theme(
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    strip.background = element_blank(),
    strip.text = element_text(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1))


ggsave(args$fig, p, width = 15, height = 6, units = "cm")