# wcs <- list(stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("plts/stat_1d_by_stat1d-dimEst,%s.rds", wcs$stat1d),
#     pdf = sprintf("plts/stat_1d_by_stat1d-dimEst,%s.pdf", wcs$stat1d))

suppressPackageStartupMessages({
    library(intrinsicDimension)
})

source(args$fun)
res <- readRDS(args$res)

df <- res %>% 
    # keep data of interest
    filter(stat1d == wcs$stat1d) %>%
    .filter_res() %>% 
    # average across groups
    group_by(refset, reftyp, method, metric, group) %>% .avg(n = 1) %>% 
    # estimate dimensionality for each refset
    pivot_wider(
        names_from = metric, 
        values_from = stat) %>% 
    split(.$refset) %>% 
    lapply(\(df) {
        if (nrow(df) < 3) return(NULL)
        ks <- seq(2, nrow(df)-1)
        mat <- as.matrix(select(df, any_of(.metrics_lab)))
        mat <- mat[, apply(mat, 2, \(.) !all(is.na(.)))]
        mat[is.na(mat)] <- 1
        est <- sapply(ks, maxLikGlobalDimEst, data = mat)
        data.frame(dim = unlist(est), k = ks)
    }) %>% 
    bind_rows(.id = "refset") %>% 
    mutate(type = res$reftyp[match(refset, res$refset)])

plt <- ggplot(df, aes(factor(k), dim, col = type, fill = type)) +
    geom_boxplot(
        size = 0.25, outlier.size = 0.25,
        alpha = 0.25, key_glyph = "point") +
    scale_x_discrete(
        "number of nearest neighbors (k)",
        breaks = seq(0, 20, 2)) +
    scale_y_continuous(
        "estimated dimensionality",
        limits = range(df$dim),
        breaks = seq(0, 10, 2))

thm <- theme(panel.grid.major = element_line(color = "grey"))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 9, height = 6, units = "cm")
