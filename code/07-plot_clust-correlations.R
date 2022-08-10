# args <- list(
#     uts = "code/utils-plotting.R",
#     rds = "plts/clust-correlations.rds",
#     pdf = "plts/clust-correlations.pdf",
#     res = list.files("outs", "^clust_res", full.names = TRUE))

source(args$uts)

res <- .read_res(args$res)

mat <- res %>%
    pivot_wider(
        id_cols = c("refset", "cluster", "clust_method"),
        names_from = "sim_method",
        values_from = "F1") %>%
    select(any_of(c("ref", names(.methods_pal)))) %>%
    cor(method = "pearson", use = "pairwise.complete.obs")

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

fd <- filter(df, from != to)
min <- floor(min(fd$corr)/0.1)*0.1
max <- ceiling(max(fd$corr)/0.1)*0.1
plt <- ggplot(fd, aes(from, to, fill = corr)) +
    geom_tile() +
    scale_fill_gradientn("r",
        colors = rev(hcl.colors(11, "Grays")),
        limits = c(min, max), breaks = c(min, max)) +
    coord_equal(expand = FALSE) +
    scale_x_discrete(limits = rev(xo[-1])) 

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