source(args$fun)

# args <- list(res = list.files("results", "stat_1d.*ks\\.", full.names = TRUE))
# #args$res <- sample(args$res, 100)
# wcs <- list(stat1d = "ks")

df <- .read_res(args$res) %>% 
    mutate(refset = paste(datset, subset, sep = ",")) %>% 
    group_by(refset, method, metric, group) %>% 
    summarise(stat = mean(stat), .groups = "drop_last") %>% 
    mutate(n = n()) %>% 
    filter(n == 1 | group != "global") %>% 
    mutate(method = droplevels(method))

switch(wcs$stat1d, 
    ks = {
        ylim <- 1
        ylab <- "KS statistic"
    },
    ws = {
        ylim <- NA
        ylab <- "Wasserstein metric"
    })

plt <- ggplot(df, aes(
    reorder_within(method, stat, metric), 
    stat, col = method, fill = method)) +
    facet_wrap(~ metric, nrow = 2, scales = "free_x") +
    geom_boxplot(
        outlier.size = 0.25, outlier.alpha = 1,
        size = 0.25, alpha = 0.25, key_glyph = "point") + 
    scale_fill_manual(values = .methods_pal) +
    scale_color_manual(values = .methods_pal) +
    scale_y_continuous(limits = c(0, ylim), n.breaks = 3) +
    labs(x = NULL, y = ylab)

thm <- theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)
saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 6, units = "cm")
