# wcs <- list(val = "cms")
# args <- list(
#     uts1 = "code/utils-plotting.R",
#     uts2 = "code/utils-integration.R",
#     rds = paste0("plts/batch-densities_", wcs$val, ".rds"),
#     pdf = paste0("plts/batch-densities_", wcs$val, ".pdf"),
#     res = list.files("outs", "^batch_res", full.names = TRUE))

source(args$uts1)
source(args$uts2)

res <- .read_res(args$res)

lim <- switch(wcs$val, bcs = c(0, 1), c(-0.5, 0.5))

fig <- if (wcs$val != "bcs") {
    df <- .cms_ldf(res)
    plt <- ggplot(df, aes(
        .data[[wcs$val]], ..ndensity.., 
        col = batch_method, fill = batch_method)) +
        facet_grid(sim_method ~ refset) +
        geom_vline(xintercept = 0, size = 0.2) +
        geom_density(alpha = 0, key_glyph = "point") +
        scale_x_continuous(limits = lim, n.breaks = 3) +
        scale_y_continuous(limits = c(0, 1), n.breaks = 3) +
        labs(x = .batch_labs[wcs$val], y = "scaled density")
    thm <- theme(axis.text.x = element_text(angle = 45, hjust = 1))
    .prettify(plt, thm)
}

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 12, units = "cm")