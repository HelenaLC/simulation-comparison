source("scripts/utils-plotting.R")

pat <- "stat_1d_by_reftyp-heatmap,(n|b|k|g),ks\\.rds"
fns <- list.files("plots", pat, full.names = TRUE)
names(fns) <- typ <- gsub(pat, "\\1", basename(fns))

ps <- lapply(fns, readRDS)
ps <- ps[c("n", "b", "k", "g")]

oy <- c(.gene_metrics, .none_metrics[1], .cell_metrics, .none_metrics[2])
oy <- scale_y_discrete(limits = rev(.metrics_lab[oy]))
ox <- lapply(ps, function(p) layer_scales(p)$x)
    
ps <- lapply(ps, "+", theme(axis.text.x = element_blank()))
ps[-1] <- lapply(ps[-1], "+", theme(axis.text.y = element_blank()))

ps <- lapply(seq_along(ps), function(i) {
    p <- ps[[i]]
    df <- p$data
    missing <- setdiff(
        .metrics_lab,
        levels(df$metric))
    fill <- expand_grid(
        method = levels(df$method),
        group = factor(levels(df$group), levels(df$group)),
        metric = missing,
        stat = NA)
    p$data <- bind_rows(df, fill)
    suppressMessages(p + ox[[i]] + oy)
})
ps1 <- ps

pat <- "stat_2d_by_reftyp-(n|b|k|g),ks2\\.rds"
(fns <- list.files("plots", pat, full.names = TRUE))
names(fns) <- gsub(pat, "\\1", basename(fns))

ps <- lapply(fns, readRDS)
ps <- ps[c("n", "b", "k", "g")]
oy <- scale_y_discrete(limits = rev(layer_scales(ps$n)$y$limits))
ps <- lapply(seq_along(ps), function(i) ps[[i]] + ox[[i]] + oy)
ps[-1] <- lapply(ps[-1], "+", theme(axis.text.y = element_blank()))
ps2 <- ps

ws <- sapply(ps1, function(p) {
    f <- length(p$facet$params) != 0
    n <- length(unique(p$data$method))
    ifelse(f, 0.5+2*n, n)
})

suppressMessages({
    fig <- wrap_plots(c(ps1, ps2), nrow = 2) +
        plot_layout(guides = "collect", widths = ws) +
        plot_annotation(tag_levels = "a") &
        coord_cartesian() &
        theme(
            plot.title = element_blank(),
            plot.margin = margin(1,0,1,0,"mm"),
            plot.tag = element_text(face = "bold", size = 9))
})

fnm <- "stat1n2d_by_reftyp.pdf"
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 16, height = 10, units = "cm")
