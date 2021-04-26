source(args$fun)

df <- .read_res(unlist(args$res)) %>%
  filter(group == "global", !is.na(stat)) %>%
  mutate(refset = paste(datset, subset, sep = ",")) %>%
  select(-c(group, id, datset, subset))

gg <- pivot_wider(df,
  names_from = stat1d,
  values_from = stat) %>% 
  group_by(refset, metric) %>%
  mutate(
    ks = ks/max(ks, na.rm = TRUE),
    ws = ws/max(ws, na.rm = TRUE))

plt <- ggplot(gg, aes(ws, ks)) +
  facet_wrap(~ metric, nrow = 2) + 
  geom_abline(intercept = 0, slope = 1, size = 0.2, lty = 2) +
  stat_smooth(method = "lm", formula = y ~ x, size = 0.4, col = "red") +
  geom_point(alpha = 0.2, size = 1, shape = 16, col = "tomato") + 
  stat_cor(method = "pearson", size = 1.5,
    hjust = 1, vjust = 0, label.x.npc = 1, label.y.npc = 0) +
  scale_x_continuous(limits = c(0, 1), breaks = c(0, 1)) +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 1)) +
  labs(x = "scaled Wasserstein metric", y = "scaled KS statistic")

thm <- theme(
  aspect.ratio = 1,
  legend.position = "none")

fig <- .prettify(plt, thm)

saveRDS(fig, args$ggp)
ggsave(args$plt, fig, width = 16, height = 7.5, units = "cm")
