source(args$fun)

df <- .read_res(args$res) %>% 
  filter(group == "global") %>%
  filter(!grepl("sil|exp", metric))

plt <- ggplot(df, aes(value, ..ndensity..)) +
  facet_grid(method ~ metric, scales = "free_x") +
  geom_density(alpha = 0.2, size = 0.2, col = "red", fill = "tomato") +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 1)) +
  labs(x = NULL, y = "normalized density")

thm <- theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))

fig <- .prettify(plt, thm)
n <- nlevels(df$method)

saveRDS(fig, args$ggp)
ggsave(args$plt, fig, 
  width = 18, 
  height = 1+n, 
  units = "cm")
