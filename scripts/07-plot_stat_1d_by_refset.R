source(args$fun)
res <- .read_res(args$res)

df <-  res %>% 
    group_by(method, metric, group) %>% 
    summarise_at("stat", mean) %>% 
    mutate(group = relevel(factor(group), ref = "global"))

plt <- ggplot(df, aes(method, metric, fill = stat)) +
    (if (!all(df$group == "global")) facet_grid(~ group)) +
    geom_tile() +
    scale_fill_viridis_c(
        .stats1d_lab[wcs$stat1d],
        limits = c(0, NA),
        na.value = "grey") +
    coord_equal(expand = FALSE) +
    ggtitle(paste("refset:", wcs$refset))

thm <- theme(
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

p <- .prettify(plt, thm)
saveRDS(p, args$ggp)
ggsave(args$plt, p, width = 6, height = 4, units = "cm")
