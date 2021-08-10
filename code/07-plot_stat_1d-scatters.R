# args <- list(
#   fun = "code/utils.R",
#   res = "outs/obj-stat_1d.rds",
#   rds = "plts/stat_1d-scatters.rds",
#   pdf = "plts/stat_1d-scatters.pdf")

source(args$fun)

res <- readRDS(args$res)
  
df <- res %>% 
  mutate(refset = paste(datset, subset, sep = ",")) %>%
  select(-c(datset, subset)) %>% 
  # for type != n, keep batch-/cluster-level comparisons only
  group_by(stat1d, refset, method, metric) %>% 
  mutate(n = n()) %>% 
  filter(group != "global" | n == 1) %>%  
  select(-c(group, n)) %>% 
  # for each statistic & metric, re-scale b/w 0 & 1 
  group_by(stat1d, metric) %>% 
  mutate(stat = stat/max(stat, na.rm = TRUE)) %>% 
  pivot_wider(names_from = stat1d, values_from = stat) %>% 
  filter(!is.na(ks), !is.na(ws))

plt <- ggplot(df, aes(ks, ws, col = refset, fill = refset)) +
  facet_wrap(~ metric, nrow = 2) +
  stat_cor(
    aes(group = metric), method = "spearman",
    label.x = 0, label.y = 1, vjust = 1, size = 1.5) +
  geom_point(size = 0.2, alpha = 0.4, show.legend = FALSE) +
  scale_x_sqrt(limits = c(0, 1), breaks = seq(0.2, 1, 0.2)) +
  scale_y_sqrt(limits = c(0, 1), breaks = seq(0.2, 1, 0.2)) +
  labs(x = "KS statistics", y = "scaled Wasserstein metric")

thm <- theme(aspect.ratio = 1)

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 7.5, units = "cm")
