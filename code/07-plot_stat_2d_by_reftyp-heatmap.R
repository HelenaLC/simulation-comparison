source(args$fun)
res <- .read_res(args$res)

df <-  res %>%
    mutate(metrics = paste(metric1, metric2, sep = "\n")) %>% 
    group_by(method, metrics, group, datset, subset) %>% 
    summarise_at("stat", mean) %>% # average across groups
    summarise_at("stat", mean) %>% # average across subsets
    summarise_at("stat", mean) %>% # average across datsets
    # keep batch-/cluster-level comparisons only
    mutate(n = n()) %>% filter(n == 1 | group != "global")

if (wcs$reftyp != "n") 
    # except for global summaries, keep 
    # batch-/cluster-level comparisons only
    df <- filter(df, group != "global")
    
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
    group_by(metrics) %>% 
    summarise_at("stat", mean) %>% 
    arrange(desc(stat)) %>% 
    pull("metrics")

df <- df %>% complete(method, metrics, fill = list(stat = NA))

plt <- ggplot(df, 
    aes(method, metrics, fill = stat)) +
    geom_tile(col = "white") +
    scale_fill_distiller(
        .stats2d_lab[wcs$stat2d],
        palette = "RdYlBu",
        na.value = "lightgrey",
        limits = c(0, 1), 
        breaks = c(0, 1)) +
    coord_equal(3/2, expand = FALSE) +
    scale_x_discrete(limits = rev(ox)) +
    scale_y_discrete(limits = rev(oy)) 

thm <- theme(
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 7.5, height = 6, units = "cm")
