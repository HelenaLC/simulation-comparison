source(args$fun)
df <-  .read_res(args$res)

.p <- function(df, x, nr, nc, scales) {
    ggplot(df,
        aes_string(x, "value", col = "method", fill = "method")) +
        facet_wrap( ~ metric,
            nrow = nr,
            ncol = nc,
            scales = scales) +
        geom_boxplot(
            alpha = 0.25,
            width = 0.75,
            size = 0.25,
            key_glyph = "point",
            outlier.size = 0.1) +
        scale_x_reordered() +
        scale_fill_manual(NULL, values = .methods_pal) +
        scale_color_manual(NULL, values = .methods_pal) 
}

thm <- theme(
    axis.title = element_blank(),
    axis.ticks.x = element_blank())

if (all(df$group == "global")) {
    h <- 6
    nr <- 2
    nc <- NULL
    scales <- "free"
    x <- "reorder_within(method, value, metric)"
    plt <- .p(df, x, nr, nc, scales)
    thm <- thm + theme(axis.text.x = element_blank())
    p <- .prettify(plt, thm)
} else {
    h <- 9
    nr <- NULL
    nc <- 2
    scales <- "free_y"
    x <- "id"
    
    sep <- grep("silhouette|percent", levels(df$metric), value = TRUE)

    p1 <- .p(filter(df, !metric %in% sep), x, nr, nc, scales)
    p2 <- .p(filter(df,  metric %in% sep), x, nr, nc = 1, scales)
    thm <- thm + theme(axis.text.x = element_text(angle = 30, hjust = 1))
    
    p1 <- .prettify(p1, thm)
    p2 <- .prettify(p2, thm) + theme(axis.text.x = element_blank())
    l <- "
    AB
    AC
    "
    p <- p1 + p2 + guide_area() +
        plot_layout(
            design = l,
            widths = c(3, 1),
            heights = c(4, 1),
            guides = "collect")
}

saveRDS(p, args$ggp)
ggsave(args$plt, p, width = 15, height = h, units = "cm")
