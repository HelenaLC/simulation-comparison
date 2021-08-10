source(args$fun)

res <- args$res %>% 
    lapply(readRDS) %>% 
    bind_rows() %>% 
    mutate(refset = paste(datset, subset, sep = ",")) %>% 
    select(-c(datset, subset))

df <- res %>% 
    group_by(
        refset,
        simulation_method,
        clustering_method) %>% 
    summarise_at("F1", mean) %>% 
    mutate(rank = rank(-F1)) 

plt <- ggplot(df, aes(
    reorder_within(clustering_method, rank, refset), 
    simulation_method, fill = rank)) +
    facet_wrap(~ refset, nrow = 1, scales = "free_x") +
    geom_tile(col = "white", key_glyph = "point") +
    scale_fill_gradientn(
        colors = rev(hcl.colors(5, "Spectral")),
        limits = range(df$rank), 
        breaks = range(df$rank),
        labels = c("best", "worst")) +
    guides(fill = guide_colorbar(reverse = TRUE)) +
    coord_cartesian(expand = FALSE) +
    scale_x_reordered()

thm <- theme(
    axis.title = element_blank(),
    axis.text.x = element_text(size = 4, angle = 45, hjust = 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$ggp)
ggsave(args$plt, fig, width = 16, height = 3.25, units = "cm")
