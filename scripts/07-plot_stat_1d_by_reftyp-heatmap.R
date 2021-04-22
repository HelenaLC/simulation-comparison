source(args$fun)
res <- .read_res(args$res)

df <- res %>%
    group_by(metric, method, 
        group, datset, subset) %>% 
    summarize_at("stat", mean) %>% # average across groups
    summarize_at("stat", mean) %>% # average across subsets
    summarize_at("stat", mean) %>% # average across datsets
    mutate(group = relevel(factor(group), ref = "global"))

# order methods by average across metrics
ox <- df %>% 
    group_by(method) %>% 
    summarise_at("stat", mean) %>% 
    arrange(desc(stat)) %>% 
    pull("method")

# order metrics by average across methods
oy <- df %>% 
    group_by(metric) %>% 
    summarise_at("stat", mean) %>% 
    arrange(desc(stat)) %>% 
    pull("metric")

df <- df %>% complete(metric, method, group, fill = list(stat = NA))
facet <- if (!all(df$group == "global")) facet_grid(~ group)

plt <- ggplot(df, 
    aes(method, metric, fill = stat)) +
    geom_tile(col = "white") + facet +
    scale_fill_gradientn(
        .stats1d_lab[wcs$stat1d],
        limits = c(0, 1), 
        na.value = "lightgrey",
        colors = rev(hcl.colors(9, "RdPu"))) +
    coord_equal(expand = FALSE) +
    scale_x_discrete(limits = rev(ox)) + 
    scale_y_discrete(limits = rev(oy))

thm <- theme(
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

p <- .prettify(plt, thm)
saveRDS(p, args$ggp)
ggsave(args$plt, p, width = 6, height = 6, units = "cm")