source(args$fun)
res <- .read_res(args$res)

df <-  res %>%
    group_by(method, metric1, metric2, group) %>% 
    summarise_at("stat", mean) %>% 
    mutate(group = relevel(factor(group), ref = "global")) %>% 
    mutate(metrics = paste(metric1, metric2, sep = "\n"))

# order methods by average across metrics
ox <- df %>% 
    group_by(method) %>% 
    summarise_at("stat", mean) %>% 
    arrange(desc(stat)) %>% 
    pull("method")

# order metrics by average across methods
oy <- df %>% 
    group_by(metrics) %>% 
    summarise_at("stat", mean) %>% 
    arrange(desc(stat)) %>% 
    pull("metrics")

plt <- ggplot(df, aes(method, metrics, fill = stat)) +
    (if (!all(df$group == "global")) facet_grid(~ group)) +
    geom_tile(col = "white") +
    scale_fill_viridis_c(
        .stats2d_lab[wcs$stat2d],
        limits = c(0, NA),
        na.value = "grey") +
    coord_equal(3/2, expand = FALSE) +
    scale_x_discrete(limits = rev(ox)) +
    scale_y_discrete(limits = rev(oy)) +
    ggtitle(paste("refset:", wcs$refset))

thm <- theme(
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

p <- .prettify(plt, thm)
saveRDS(p, args$ggp)
ggsave(args$plt, p, width = 7.5, height = 6, units = "cm")