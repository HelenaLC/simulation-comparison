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

mat <- res %>% 
    group_by(sim_method, batch_method, refset, batch) %>% 
    fun() %>% # average across cells
    fun() %>% # average across batches
    ungroup() %>% 
    pivot_wider(
        values_from = wcs$val,
        names_from = "sim_method",
        id_cols = c("refset", "batch_method")) %>% 
    select(any_of(c("ref", names(.methods_pal)))) %>% 
    cor(method = "pearson")

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

lab <- switch(wcs$val, 
    cms = "CMS", 
    ldf = expression(Delta~"LDF"),
    avg = "Average\nscore")

plt <- ggplot(df, aes(from, to, fill = corr)) +
    geom_tile() +
    scale_fill_distiller(
        expression(rho),
        palette = "RdYlBu",
        na.value = "lightgrey",
        direction = -1,
        limits = c(0, 1),
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