source(args$fun)

# args <- list(res = list.files("outs", "batch_res", full.names = TRUE))

res <- .read_res(args$res) %>%
    dplyr::rename(sim_method = method) %>%
    mutate(refset = paste(datset, subset, sep = ","))

fig <- if (wcs$val != "avg") {
    lab <- switch(wcs$val, 
        cms = "CMS", 
        ldf = expression(Delta~"LDF"),
        avg = "Average\nscore")
    
    plt <- ggplot(res, aes(
        .data[[wcs$val]], ..ndensity.., 
        col = sim_method, fill = sim_method)) +
        facet_grid(batch_method ~ refset, scales = "free_x") +
        geom_density(alpha = 0, key_glyph = "point") +
        scale_x_continuous(breaks = c(0, 0.5, 1)) +
        scale_y_continuous(breaks = c(0, 0.5, 1), limits = c(0, 1)) +
        scale_fill_manual(
            values = .methods_pal,
            breaks = levels(res$sim_method)) +
        scale_color_manual(NULL,
            values = .methods_pal,
            breaks = levels(res$sim_method)) +
        labs(x = lab, y = "scaled density")
        
    thm <- NULL
    .prettify(plt, thm)
} else NULL

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 15, height = 8, units = "cm")