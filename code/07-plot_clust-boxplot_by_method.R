source(args$uts)

res <- .read_res(args$res)

# order according to average F1 score
res$sim_method <- factor(
    res$sim_method, 
    levels = res %>% 
        group_by(sim_method) %>% 
        summarise_at("F1", mean) %>% 
        arrange(F1) %>% 
        pull("sim_method"))

plt <- ggplot(res, aes(
    reorder_within(clust_method, -F1, sim_method, median), 
    F1, col = clust_method, fill = clust_method)) +
    facet_grid(~ sim_method, scales = "free_x") +
    geom_hline(yintercept = c(0, 1), size = 0.1) +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_x_reordered(NULL) +
    scale_y_continuous(breaks = seq(0, 1, 0.2)) 

thm <- theme(
    legend.title = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 3.25, units = "cm")
