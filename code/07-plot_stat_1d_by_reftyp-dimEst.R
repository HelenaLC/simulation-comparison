# wcs <- list(reftyp = "n", stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-stat_1d.rds",
#     rds = sprintf("plts/stat_1d_by_reftyp-dimEst,%s,%s.rds", wcs$reftyp, wcs$stat1d),
#     pdf = sprintf("plts/stat_1d_by_reftyp-dimEst,%s,%s.pdf", wcs$reftyp, wcs$stat1d))

suppressPackageStartupMessages({
    library(intrinsicDimension)
})

source(args$fun)
res <- readRDS(args$res)

df <- res %>% 
    # keep data of interest
    filter(
        reftyp == wcs$reftyp, 
        stat1d == wcs$stat1d) %>%
    .filter_res() %>% 
    # average across groups
    group_by(refset, method, metric, group) %>% .avg(n = 1) %>%
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
    bind_rows(.id = "refset")

plt <- ggplot(df, aes(k, dim, col = refset, fill = refset)) +
    geom_point(shape = 21, size = 0.5) + 
    geom_line(alpha = 0.5, show.legend = FALSE) +
    scale_x_continuous(
        "number of nearest neighbors (k)",
        limits = range(df$k),
        breaks = seq(2, 20, 2)) +
    scale_y_continuous(
        "estimated dimensionality",
        limits = range(df$dim),
        breaks = seq(0, 10, 2)) +
    ggtitle(paste("reftyp:", wcs$reftyp))

thm <- theme(
    legend.title = element_blank(),
    panel.grid.major = element_line(color = "grey"))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")
