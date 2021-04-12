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

facet <- if (!all(df$group == "global")) facet_grid(~ group)

plt <- ggplot(df, 
    aes(method, metric, fill = stat)) +
    geom_tile(col = "white") + facet +
    scale_fill_viridis_c(
        .stats1d_lab[wcs$stat1d],
        limits = c(0, NA), 
        na.value = "lightgrey") +
    coord_equal(expand = FALSE) +
    scale_x_discrete(limits = rev(ox)) + 
    scale_y_discrete(limits = rev(oy)) +
    ggtitle(paste("reftyp:", wcs$reftyp))

thm <- theme(
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

p <- .prettify(plt, thm)
ggsave(args$fig, p, width = 6, height = 6, units = "cm")