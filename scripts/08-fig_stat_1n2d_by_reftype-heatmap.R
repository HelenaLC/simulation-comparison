source("scripts/utils-plotting.R")

pat <- "stat_1d_by_reftyp-heatmap,([a-z]),ks\\.rds"
fns <- list.files("plots", pat, full.names = TRUE)
names(fns) <- typ <- gsub(pat, "\\1", basename(fns))

ps <- lapply(fns, readRDS)
ps <- ps[c("n", "b", "k")]
ps[-1] <- lapply(ps[-1], "+", 
    theme(axis.text.y = element_blank()))
ps <- lapply(ps, function(p) {
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
    suppressMessages(p + scale_y_discrete(limits = rev(.metrics_lab)))
})
ps1 <- ps

pat <- "stat_2d_by_reftyp-([a-z]),ks2\\.rds"
(fns <- list.files("plots", pat, full.names = TRUE))
names(fns) <- gsub(pat, "\\1", basename(fns))

ps <- lapply(fns, readRDS)
ps <- ps[c("n", "b", "k")]
oy <- layer_scales(ps$n)$y$limits
ps[-1] <- lapply(ps[-1], "+", 
    theme(axis.text.y = element_blank()))
ps2 <- ps

suppressMessages({
    fig <- wrap_plots(c(ps1, ps2), 
        nrow = 2, ncol = 3,
        widths = c(1.5, 1, 1),
        heights = c(1, 1.25)) + 
        plot_layout(guides = "collect") +
        plot_annotation(tag_levels = "a") &
        coord_cartesian() &
        theme(plot.title = element_blank())
})

fnm <- "stat1n2d_by_reftyp-heatmap.pdf"
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 15, height = 10, units = "cm")
