# wcs <- list(val = "cms")
# args <- list(
#     fun = "code/utils.R",
#     rds = paste0("plts/batch-heatmap_by_method_", wcs$val, ".rds"),
#     pdf = paste0("plts/batch-heatmap_by_method_", wcs$val, ".pdf"),
#     res = list.files("outs", "^batch_res", full.names = TRUE))

source(args$fun)

res <- .read_res(args$res) %>% 
    mutate(refset = paste(datset, subset, sep = ",")) %>%
    select(-c(datset, subset)) %>% 
    rename(sim_method = method) %>% 
    mutate(avg = (cms + abs(ldf)) / 2)

fun <- \(.) summarise(.,
    .groups = "drop_last",
    across(c(cms, avg), mean), 
    across(ldf, \(.) mean(abs(.))))

df <- res %>%
    group_by(refset, batch, batch_method, sim_method) %>%
    fun() %>% # average across cells
    mutate(val = .data[[wcs$val]]-.data[[wcs$val]][.data$sim_method == "ref"]) %>%
    filter(sim_method != "ref") %>%
    mutate(sim_method = droplevels(sim_method))

lab <- switch(wcs$val, 
    cms = "CMS", 
    ldf = expression(Delta~"LDF"),
    avg = "Average\nscore")

plt <- ggplot(df, aes(reorder(sim_method, val, median), val)) +
    geom_hline(yintercept = 0, size = 0.1, col = "red") +
    geom_boxplot(size = 0.2, outlier.size = 0.1, key_glyph = "point") +
    geom_violin(fill = NA, col = "grey", size = 0.2) +
    labs(x = NULL, y = bquote(Delta*.(lab)*"(sim-ref)"))

thm <- theme(axis.text.x = element_text(angle = 45, hjust = 1),)

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 6, height = 6, units = "cm")
