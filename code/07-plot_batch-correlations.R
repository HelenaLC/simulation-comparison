# wcs <- list(val = "cms")
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
    .bcs(n = 1) # average across cells & batches

mat <- df %>% 
    ungroup() %>% 
    pivot_wider(
        values_from = wcs$val,
        names_from = "sim_method",
        id_cols = c("refset", "batch_method", "batch")) %>% 
    select(any_of(c("ref", names(.methods_pal)))) %>% 
    cor(method = "pearson", use = "pairwise.complete.obs")

mat[is.na(mat)] <- 0
xo <- rownames(mat)[hclust(dist(mat))$order]
yo <- rownames(mat)[hclust(dist(t(mat)))$order]

df <- mat %>% 
    data.frame(
        from = rownames(.), 
        check.names = FALSE) %>% 
    pivot_longer(
        cols = -from, 
        names_to = "to",
        values_to = "corr") %>% 
    mutate(
        to = factor(to, levels = xo),
        from = factor(from, levels = yo)) %>% 
    filter(as.numeric(to) <= as.numeric(from))

min <- floor(min(df$corr)/0.1)*0.1
plt <- ggplot(df, aes(from, to, fill = corr)) +
    geom_tile() +
    scale_fill_distiller("r",
        palette = "RdYlBu",
        na.value = "lightgrey",
        direction = -1,
        limits = c(min, 1),
        breaks = c(0, 1)) +
    coord_equal(expand = FALSE) +
    scale_x_discrete(limits = rev(xo)) 

fy <- c("plain", "bold")[as.numeric(levels(df$to) == "ref") + 1]
fx <- c("plain", "bold")[as.numeric(rev(levels(df$from)) == "ref") + 1]

thm <- theme(
    axis.text.y = element_text(face = fy),
    axis.text.x = element_text(angle = 45, hjust = 1, face = fx),
    axis.title = element_blank(),
    panel.border = element_blank(),
    legend.title = element_text(vjust = 1),
    legend.direction = "horizontal",
    legend.position = c(1, 1),
    legend.justification = c(1, 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 6, height = 6, units = "cm")