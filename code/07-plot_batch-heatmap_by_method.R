# wcs <- list(val = "cms")
# args <- list(
#     fun = "code/utils.R",
#     rds = paste0("plts/batch-heatmap_by_method_", wcs$val, ".rds"),
#     pdf = paste0("plts/batch-heatmap_by_method_", wcs$val, ".pdf"),
#     res = list.files("outs", "^batch_res", full.names = TRUE))

source(args$fun)

res <- .read_res(args$res) %>%
    dplyr::rename(sim_method = method)

fun <- \(.) summarise(.,
    .groups = "drop_last",
    across(
        c(cms, ldf, avg), 
        \(.) mean(abs(.))))

df <- .eval_batch(res) %>% 
    group_by(refset, sim_method, batch_method, batch) %>% 
    fun() %>% # average across cells
    fun()     # average across batches

min <- floor(min(df[[wcs$val]])/0.1)*0.1
max <- ceiling(max(df[[wcs$val]])/0.1)*0.1

plt <- ggplot(df, aes(
    reorder_within(batch_method, .data[[wcs$val]], sim_method), 
    refset, fill = .data[[wcs$val]])) +
    facet_grid(~ sim_method, scales = "free_x") +
    geom_tile(col = "white") +
    scale_fill_distiller(
        .batch_labs[wcs$val],
        palette = "RdYlBu",
        limits = c(min, max),
        n.breaks = 3) +
    coord_cartesian(expand = FALSE) +
    scale_x_reordered() +
    scale_y_reordered() 

thm <- theme(
    axis.title = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 15, height = 6, units = "cm")