source(args$fun)
df <- .read_res(args$res)

pat <- "cor|pve|sw"
pairs <- c(
  asplit(combn(.metrics_lab[grep(pat, .gene_metrics, invert = TRUE, value = TRUE)], 2), 2),
  asplit(combn(.metrics_lab[grep(pat, .cell_metrics, invert = TRUE, value = TRUE)], 2), 2))

df <- df %>% 
  filter(group == "global") %>% 
  select(-c(group, id)) %>% 
  filter(metric %in% unlist(pairs))

gg <- lapply(pairs, function(i) {
  df %>% 
    filter(metric %in% i) %>% 
    group_by(datset, subset, method, metric) %>% 
    mutate(n = row_number()) %>% 
    pivot_wider(
      names_from = "metric",
      values_from = "value") %>% 
    rename(x = i[1], y = i[2]) %>%
    mutate(metrics = paste(i, collapse = "\n")) %>% 
    select(-n) %>% ungroup()
}) 

ps <- lapply(seq_along(gg), function(i) {
  lab <- paste(pairs[[i]], collapse = ", ")
  if (i == 1) lab <- paste(lab, "(x, y)")
  plt <- ggplot(slice_sample(gg[[i]], n = 1e4),
    aes(x, y, col = method, fill = method)) +
    facet_wrap(~ method, nrow = ifelse(nlevels(df$method) > 8, 2, 1)) +
    geom_point_rast(size = 0.1, alpha = 0.1, shape = 16) +
    geom_smooth(size = 0.3, show.legend = FALSE,
      method = "loess", formula = y ~ x, span = 0.25, se = FALSE) +
    scale_fill_manual(values = .methods_pal) +
    scale_color_manual(values = .methods_pal) +
    ggtitle(lab)
  .prettify(plt)
})

fig <- wrap_plots(ps, ncol = 1) +
  plot_layout(guides = "collect") &
  theme(
    legend.position = "bottom",
    axis.title = element_blank(),
    strip.text = element_blank())

ggsave(args$fig, fig, width = 15, height = 21, units = "cm")
