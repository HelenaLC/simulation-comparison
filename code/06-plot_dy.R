suppressPackageStartupMessages({
    library(jsonlite)
    library(ggplot2)
    library(purrr)
})

# args <- list(res = "results/dy-CellBench,H1975,cell_frq,cell_lls.rds")
# wcs <- list(metric1 = "cell_frq", metric2 = "cell_lls")

# con <- fromJSON("config/metrics.json")
# labs <- map(con[unlist(wcs)], "lab")
labs <- c(paste0(wcs$type, '_', wcs$metric1), paste0(wcs$type, '_', wcs$metric2))

df <- readRDS(args$res)
p <- ggplot(df, aes(x, dy, col = method)) +
    facet_wrap(c("group", "id"), 
        labeller = labeller(.multi_line = FALSE, sep = ";")) +
    geom_hline(yintercept = 0, size = 0.2) +
    geom_point(size = 0.25, alpha = 0.25) +
    geom_smooth(method = "loess", formula = y ~ x, 
        size = 0.5, se = FALSE, show.legend = FALSE) + 
    scale_color_manual(values = .pal) +
    guides(col = guide_legend(override.aes = list(alpha = 1, size = 2))) +
    labs(x = labs[[1]], y = paste("difference in", labs[[2]])) +
    .prettify("linedraw") + ggtitle(wcs$refset)

ggsave(args$fig, p, width = 15, height = 8, units = "cm")