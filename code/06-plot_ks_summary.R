suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
})

res <- lapply(args$res, readRDS)
res <- res[vapply(res, function(.) 
    !isTRUE(is.na(.)), logical(1))]

refsets <- gsub(".*-(.*),.*\\.rds", "\\1", basename(args$res))
metrics <- gsub(".*,(.*)\\.rds", "\\1", basename(args$res))

ns <- vapply(res, nrow, numeric(1))
df <- mutate(bind_rows(res),
    refset = rep.int(refsets, ns),
    metric = rep.int(metrics, ns))

p <- ggplot(df, aes(method, stat, 
    shape = group, col = method)) +
    facet_grid(metric ~ refset) +
    geom_point(size = 1, 
        position = position_dodge(0.5)) + 
    scale_color_manual(values = .pal) +
    guides(
        col = guide_legend(
            override.aes = list(size = 2)),
        shape = guide_legend(order = 1, 
            override.aes = list(size = 2))) + 
    scale_y_continuous(limits = c(0, 1)) +
    labs(x = NULL, y = "KS statistic") +
    .prettify("linedraw") + theme(
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        panel.grid.major.y = element_line())

ggsave(args$fig, p, width = 15, height = 8, units = "cm")
