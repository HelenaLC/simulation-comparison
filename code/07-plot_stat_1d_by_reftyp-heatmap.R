source(args$fun)
res <- .read_res(args$res)

df <- res %>%
    group_by(metric, method, group, datset, subset) %>% 
    summarize_at("stat", mean) %>% # average across groups
    summarize_at("stat", mean) %>% # average across subsets
    summarize_at("stat", mean)     # average across datsets

if (wcs$reftyp != "n")
    # except for global summaries, keep 
    # batch-/cluster-level comparisons only
    df <- filter(df,
        (group != "global") |
        (metric %in% .metrics_lab[.none_metrics]))

if (wcs$reftyp == "g") 
    df <- df %>% 
    rowwise() %>% 
    mutate(
        group = as.character(group),
        group = case_when(
            group != "global" ~ "group", 
            TRUE ~ group)) %>% 
    ungroup()

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

df <- df %>% complete(method, metric, fill = list(stat = NA))

plt <- ggplot(df, 
    aes(method, metric, fill = stat)) +
    geom_tile(col = "white") + 
    scale_fill_distiller(
        .stats1d_lab[wcs$stat1d],
        palette = "RdYlBu",
        na.value = "lightgrey",
        limits = c(0, 1),
        breaks = c(0, 1)) +
    coord_equal(expand = FALSE) +
    scale_x_discrete(limits = rev(ox)) + 
    scale_y_discrete(limits = rev(oy))

thm <- theme(
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 8, height = 6, units = "cm")