source(args$fun)

res <- .read_res(args$res) %>% 
    mutate(refset = paste(datset, subset, sep = ",")) %>%
    select(-c(datset, subset)) %>% 
    rename(sim_method = method)

df <- res %>% 
    group_by(
        refset,
        sim_method,
        clust_method) %>% 
    summarise_at("F1", mean) %>% 
    mutate(rank = rank(-F1))

plt <- ggplot(df, aes(
    reorder_within(clust_method, rank, sim_method), 
    reorder(refset, rank), fill = rank)) +
    facet_wrap(~ sim_method, nrow = 1, scales = "free_x") +
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

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 3.25, units = "cm")
