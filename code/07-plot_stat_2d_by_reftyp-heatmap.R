# wcs <- list(stat2d = "emd", reftyp = "b")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_2d.rds",
#     rds = "plts/stat_2d_by_reftyp-boxplot,b,ks2.rds",
#     pdf = "plts/stat_2d_by_reftyp-boxplot,b,ks2.pdf")

source(args$fun)
res <- .read_res(args$res)

df <-  res %>%
     mutate(metrics = paste(metric1, metric2, sep = "\n")) %>% 
    # except for KNN & global summaries,
    # keep group-level comparisons only
    { if (wcs$reftyp == "n") . else
        mutate(., across(
            c(group, id), 
            as.character)) %>% 
        filter(
            (!grepl("KNN", metrics) & group != id) |
            (grepl("KNN", metrics) & group == "global") |
            any(c(metric1, metric2) %in% .metrics_lab[.none_metrics])) } %>% 
    # aggregation
    group_by(method, metrics, group, datset, subset) %>% 
    summarize_at("stat", mean, na.rm = TRUE) %>% # average across groups
    summarize_at("stat", mean, na.rm = TRUE) %>% # average across subsets
    summarize_at("stat", mean, na.rm = TRUE)     # average across datsets

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

df <- complete(df, method, metrics, fill = list(stat = NA))

plt <- ggplot(df, 
    aes(method, metrics, fill = stat)) +
    geom_tile(col = "white") +
    scale_fill_distiller(
        .stats2d_lab[wcs$stat2d],
        palette = "RdYlBu",
        na.value = "grey",
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
