source(args$fun)

res <- args$res %>% 
    lapply(readRDS) %>% 
    bind_rows() %>% 
    mutate(refset = paste(datset, subset, sep = ",")) %>% 
    select(-c(datset, subset))

df <- res %>% 
    group_by(refset, cluster, clustering_method) %>% 
    mutate(F1 = F1-.data$F1[.data$simulation_method == "ref"]) %>% 
    filter(simulation_method != "ref") %>% 
    mutate(simulation_method = droplevels(simulation_method))

plt <- ggplot(df, aes(
    reorder_within(clustering_method, F1, simulation_method), 
    F1, col = clustering_method, fill = clustering_method)) +
    facet_grid(~ simulation_method, scales = "free_x") +
    geom_hline(yintercept = 0, size = 0.1) +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_x_reordered(NULL) +
    ylab(expression(Delta*"F1(sim-ref)")) 

thm <- theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    legend.title = element_blank())

fig <- .prettify(plt, thm)

saveRDS(fig, args$ggp)
ggsave(args$plt, fig, width = 16, height = 4.5, units = "cm")