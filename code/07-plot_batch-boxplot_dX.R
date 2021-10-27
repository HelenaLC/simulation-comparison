# wcs <- list(val = "ldf")
# args <- list(
#     uts1 = "code/utils-plotting.R",
#     uts2 = "code/utils-integration.R",
#     rds = paste0("plts/batch-heatmap_by_method_", wcs$val, ".rds"),
#     pdf = paste0("plts/batch-heatmap_by_method_", wcs$val, ".pdf"),
#     res = list.files("outs", "^batch_res", full.names = TRUE))

source(args$uts1)
source(args$uts2)

res <- .read_res(args$res)

df <- res %>% 
    .cms_ldf() %>% 
    .bcs(n = 1) %>% # average across cells but not batches
    group_by(refset, batch_method, batch) %>% 
    mutate(val = .data[[wcs$val]]-.data[[wcs$val]][.data$sim_method == "ref"]) %>%
    filter(sim_method != "ref") %>%
    mutate(sim_method = droplevels(sim_method))

lim <- c(
    floor(min(df$val)/0.1)*0.1, 
    ceiling(max(df$val)/0.1)*0.1)
lab <- eval(.batch_labs[wcs$val])

plt <- ggplot(df, aes(reorder(sim_method, val, median), val)) +
    geom_hline(yintercept = 0, size = 0.1, col = "red") +
    geom_boxplot(size = 0.2, outlier.size = 0.1, key_glyph = "point") +
    geom_violin(fill = NA, col = "grey", size = 0.2) +
    scale_y_continuous(limits = lim, breaks = c(0, lim)) +
    labs(x = NULL, y = bquote(Delta*.(lab)*"(sim-ref)"))

thm <- theme(axis.text.x = element_text(angle = 45, hjust = 1),)

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 6, height = 6, units = "cm")
