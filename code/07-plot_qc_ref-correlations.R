# wcs <- list(stat1d = "ks")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = "outs/obj-qc_ref.rds",
#     rds = "plts/qc_ref-correlations.rds",
#     pdf = "plts/qc_ref-correlations.pdf")

source(args$fun)
res <- readRDS(args$res)

# exclude summaries that include sampling
ex <- .metrics_lab[grep("cor|pcd", names(.metrics_lab))]
df <- res %>% 
    select(-c(datset, subset)) %>% 
    filter(!metric %in% ex) %>% 
    mutate(
        # add summary short names
        .metric = names(.metrics_lab)[match(metric, .metrics_lab)],
        # add summary type
        type = ifelse(grepl("cell", .metric), "cell", "gene")) %>% 
    # keep group-level comparisons only
    mutate(across(c(group, id), as.character)) %>%
    filter(group != id | .metric %in% .none_metrics) %>% 
    select(-c(.metric, group, id)) %>% 
    # correlate summaries of same type for each refset
    group_by(refset, metric) %>% 
    mutate(n = row_number()) %>% 
    group_by(refset, type) %>% 
    group_map(\(df, keys) {
        pivot_wider(df,
            names_from = metric, 
            values_from = value) %>% 
        select(any_of(.metrics_lab)) %>% 
        cor(method = "spearman", 
            use = "pairwise.complete.obs") %>% 
        data.frame(from = rownames(.)) %>% 
        pivot_longer(-from, names_to = "to") %>% 
        mutate(keys)
    }) %>% 
    bind_rows() %>% 
    # average across refsets
    group_by(from, to) %>% 
    mutate(value = mean(value)) %>% 
    ungroup() %>% 
    distinct(from, to, .keep_all = TRUE) %>% 
    select(-refset)

# do hierarchical clustering for each type
mat <- df %>% 
    split(.$type) %>% 
    lapply(\(df) df %>% 
        pivot_wider(
            names_from = to,
            values_from = value) %>%
            select_if(is.numeric))

o <- unlist(lapply(mat, \(.) colnames(.)[hclust(dist(.))$order]))
df <- mutate(df, across(c(from, to), factor, o, .metrics_lab[o]))

plt <- ggplot(df, aes(from, to, fill = value)) +
    geom_tile() +
    scale_fill_distiller("r",
        palette = "RdYlBu",
        limits = c(-0.5, 1),
        breaks = c(0, 1)) +
    coord_equal(expand = FALSE) +
    scale_x_discrete(limits = rev(levels(df$to))) 

thm <- theme(
    axis.title = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 7.5, height = 6, units = "cm")
