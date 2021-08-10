source(args$fun)

# args <- list(res = list.files("outs", "stat_2d-.*(ks2|emd)\\.rds", full.names = TRUE))

res <- .read_res(args$res)

df <- res %>% 
  filter(!is.na(stat)) %>%
  mutate(
    refset = paste(datset, subset, sep = ","),
    metrics = paste(metric1, metric2, sep = "\n")) %>%
  select(-c(datset, subset, metric1, metric2)) %>% 
  # for type != n, keep batch-/cluster-level comparisons only
  group_by(stat2d, refset, method, metrics) %>% 
  mutate(n = n()) %>% 
  filter(group != "global" | n == 1) %>%  
  select(-c(group, n))

gg <- pivot_wider(df,
  names_from = stat2d,
  values_from = stat) %>% 
  group_by(refset, metrics) %>%
  mutate(
    ks2 = ks2/max(ks2, na.rm = TRUE),
    emd = emd/max(emd, na.rm = TRUE))

plt <- ggplot(gg, aes(emd, ks2)) +
  facet_wrap(~ metrics, nrow = 2) + 
  geom_abline(intercept = 0, slope = 1, size = 0.2, lty = 2) +
  stat_smooth(method = "lm", formula = y ~ x, size = 0.4, col = "red") +
  geom_point(alpha = 0.2, size = 1, shape = 16, col = "tomato") + 
  stat_cor(method = "pearson", size = 1.5,
    hjust = 1, vjust = 0, label.x.npc = 1, label.y.npc = 0) +
  scale_x_continuous(limits = c(0, 1), breaks = c(0, 1)) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 1)) +
  labs(x = "scaled EMD", y = "scaled KS statistic")

thm <- theme(
  aspect.ratio = 1,
  legend.position = "none")

fig <- .prettify(plt, thm)

saveRDS(fig, args$ggp)
ggsave(args$plt, fig, width = 16, height = 9.25, units = "cm")
