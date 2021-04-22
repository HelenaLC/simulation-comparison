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
    return(p)
})
suppressMessages({
    fig <- wrap_plots(ps, nrow = 1) +
        plot_layout(guides = "collect") +
        plot_annotation(tag_levels = "a") &
        scale_y_discrete(limits = rev(.metrics_lab)) &
        theme(plot.title = element_blank())
})

fnm <- "stat_1d_by_reftype-heatmap.pdf"
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 15, height = 5, units = "cm")   