source(args$uts)

res <- .read_res(args$res)

df <- res %>%
    group_by(refset, cluster, clust_method) %>%
    mutate(F1 = F1-.data$F1[.data$sim_method == "ref"]) %>%
    filter(sim_method != "ref") %>%
    mutate(sim_method = droplevels(sim_method))

plt <- ggplot(df, aes(reorder(sim_method, F1, median), F1)) +
    geom_hline(yintercept = 0, size = 0.1, col = "red") +
    geom_boxplot(size = 0.2, outlier.size = 0.1, key_glyph = "point") +
    geom_violin(fill = NA, col = "grey", size = 0.2) +
    scale_y_continuous(limits = c(-1, 1), n.breaks = 5) +
    labs(x = NULL, y = expression(Delta*"F1(sim-ref)"))

thm <- theme(axis.text.x = element_text(angle = 45, hjust = 1),)

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 6, height = 6, units = "cm")
