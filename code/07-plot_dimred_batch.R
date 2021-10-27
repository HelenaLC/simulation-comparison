# args <- list(
#     rds = "plts/batch-dimred.rds",
#     pdf = "plts/batch-dimred.pdf",
#     uts = "code/utils-plotting.R",
#     res = list.files("outs", "^dr_", full.names = TRUE))
# args$res <- grep("CellBench,H", args$res, value = TRUE)

source(args$uts)

res <- .read_res(args$res)
    
dfs <- res %>% 
    replace_na(list(batch_method = "none")) %>%
    mutate(
        batch_method = factor(batch_method),
        batch_method = relevel(batch_method, "none")) %>% 
    group_split(refset)

lys <- lapply(dfs, \(df) {
    plt <- ggplot(df, aes(TSNE1, TSNE2, col = batch, fill = batch)) +
        facet_grid(batch_method ~ sim_method, scales = "free") +
        geom_point_rast(shape = 21, size = 0.05, alpha = 0.2) +
        ggtitle(df$refset[1])
    thm <- theme(
        aspect.ratio = 1,
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_text(hjust = 0))
    fig <- .prettify(plt, thm)
})

saveRDS(lys, args$rds)

pdf(args$pdf, width = 16/2.54, height = 12/2.54)
for (p in lys) print(p); dev.off()
