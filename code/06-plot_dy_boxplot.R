suppressPackageStartupMessages({
    library(jsonlite)
    library(ggplot2)
    library(purrr)
})

# args <- list(res = "results/dy-CellBench,H1975,cell_frq,cell_lls.rds")
# wcs <- list(metric1 = "cell_frq", metric2 = "cell_lls")

con <- fromJSON("config/metrics.json")
labs <- map(con[unlist(wcs)], "lab")

df <- readRDS(args$res)
df$foo <- with(df, paste(group, id, sep = "\n"))
p <- ggplot(df, aes(foo, dy, fill = method, col = method)) +
    geom_hline(yintercept = 0, size = 0.2) +
    geom_boxplot(key_glyph = "point",
        outlier.size = 0.25, alpha = 0.25) +
    scale_fill_manual(values = .pal) +
    scale_color_manual(values = .pal) +
    guides(col = guide_legend(override.aes = list(alpha = 1, size = 2))) +
    labs(x = labs[[1]], y = paste("difference in", labs[[2]])) +
    .prettify("linedraw") + ggtitle(wcs$refset)

ggsave(args$fig, p, width = 7.5, height = 5, units = "cm")
