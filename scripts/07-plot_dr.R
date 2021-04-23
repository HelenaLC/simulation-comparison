source(args$fun)
df <- .read_res(args$res)

i <- c("lls", "cluster", "batch")
i <- intersect(i, names(df))

ps <- lapply(i, function(.) {
    plt <- ggplot(df, aes(TSNE1, TSNE2, 
        col = .data[[.]], fill = .data[[.]])) +
        (if (length(i) == 1) {
            facet_wrap(~ method, nrow = 2) 
        } else {
            facet_grid(~ method)
        }) +
        geom_point_rast(size = 0.2, alpha = 0.2, shape = 21)
        if (is.numeric(df[[.]])) {
            pal <- rev(hcl.colors(10, "RdPu"))
            plt <- plt + 
                scale_fill_gradientn(colors = pal) +
                scale_color_gradientn(colors = pal) 
        } else {
            n <- length(unique(df[[.]]))
            pal <- if (n <= 9) {
                brewer.pal(n, "Set2")
            } else {
                colorRampPalette(brewer.pal(9, "Set1"))(n)
            }
            plt <- plt + 
                scale_fill_manual(NULL, values = pal) +
                scale_color_manual(NULL, values = pal)
        }
    thm <- theme(
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.spacing = unit(2, "mm"),
        axis.title = element_text(hjust = 0),
        legend.justification = c(0, 0.5))
    .prettify(plt, thm)
})

if (length(ps) > 1) {
    ps[-1] <- lapply(ps[-1], "+", theme(
        strip.text = element_blank(),
        strip.background = element_blank()))
    ps[-length(ps)] <- lapply(ps[-length(ps)], "+", theme(
        axis.title = element_blank()))
}

(p <- wrap_plots(ps, ncol = 1))

if (length(i) == 1) {
    w <- 2*nlevels(df$method)+2
    h <- 8*length(i)
} else {
    w <- 4*nlevels(df$method)+2
    h <- 4*length(i)
}

saveRDS(p, args$ggp)
ggsave(args$plt, p, width = w, height = h, units = "cm")