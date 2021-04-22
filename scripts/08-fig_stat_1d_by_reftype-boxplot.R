source("scripts/utils-plotting.R")

pat <- "stat_1d_by_reftyp-boxplot,([a-z]),ks\\.rds"
fns <- list.files("plots", pat, full.names = TRUE)
names(fns) <- typ <- gsub(pat, "\\1", basename(fns))

ps <- lapply(fns, readRDS)
ps <- ps[c("n", "b", "k")]
ps[[1]] <- ps[[1]] + facet_wrap(~metric, ncol = 4, scales = "free_x")
ps[-1] <- lapply(ps[-1], "+", facet_wrap(~metric, ncol = 5, scales = "free_x"))

suppressMessages({
    fig <- wrap_plots(ps, ncol = 1) +
        plot_annotation(tag_levels = "a") &
        scale_y_continuous(limits = c(0, 1)) &
        theme(plot.title = element_blank())
})

fnm <- "stat_1d_by_reftype-boxplot.pdf"
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 15, height = 12, units = "cm")
