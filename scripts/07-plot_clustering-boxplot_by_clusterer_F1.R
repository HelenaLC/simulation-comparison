source(args$fun)

res <- args$res %>%
    lapply(readRDS) %>%
    bind_rows() %>%
    mutate(refset = paste(datset, subset, sep = ",")) %>%
    select(-c(datset, subset))

# order according to average F1 score
res$clustering_method <- factor(
    res$clustering_method, 
    levels = res %>% 
        group_by(clustering_method) %>% 
        summarise_at("F1", mean) %>% 
        arrange(F1) %>% 
        pull("clustering_method"))

pal <- .methods_pal[levels(res$simulation_method)]

plt <- ggplot(res, aes(
    reorder_within(simulation_method, F1, clustering_method), 
    F1, col = simulation_method, fill = simulation_method)) +
    facet_grid(~ clustering_method, scales = "free_x") +
    geom_hline(yintercept = c(0, 1), size = 0.1) +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_fill_manual(values = pal) +
    scale_color_manual(values = pal) +
    scale_x_reordered(NULL) +
    scale_y_continuous(breaks = seq(0, 1, 0.2)) 

thm <- theme(
    legend.title = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

(fig <- .prettify(plt, thm))

saveRDS(fig, args$ggp)
ggsave(args$plt, fig, width = 16, height = 3.25, units = "cm")
