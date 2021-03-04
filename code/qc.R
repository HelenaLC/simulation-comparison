ref <- readRDS("data/ref/Kang18,muscat.rds")
sim <- readRDS("data/sim/Kang18,muscat.rds")

sim <- simData_muscat(ref, ke = "remove", pde = 0.25)
sim <- logNormCounts(sim)

rd <- rowData(sim)
gs <- data.frame(rd) %>% 
    filter(specs == 1) %>% 
    mutate(
        gene = rownames(.),
        nodes = unlist(nodes)) %>% 
    group_by(nodes) %>% 
    slice_max(logFC, n = 5) %>% 
    pull("gene")

nk <- length(kids <- levels(sim$cluster))
vapply(rd$nodes, function(.) if (is.na(.)) logical(nk) else . %in% kids, logical(nk))
nodes <- matrix(0, nrow(sim), nk, dimnames = list(rownames(sim), kids))

# cs <- unlist(lapply(split(seq(ncol(sim)), sim$cluster), sample, 50))
# scater::plotHeatmap(sim[, cs], gs, center = TRUE)

rd[gs, ]
head(rd$beta$k[gs, ])

plotExprHeatmap(.catalyst(sim), gs, by = "cluster_id", 
    fun = "mean", scale = "last", q = 0,
    hm_pal = hcl.colors(10, "Lajolla"),
    row_anno = FALSE)

gs <- data.frame(rd) %>% 
    filter(specs == 3) %>% 
    mutate(
        gene = rownames(.),
        nodes = lapply(nodes, paste, collapse = ".")) %>% 
    group_by(nodes) %>% 
    slice_max(logFC, n = 5) %>% 
    pull("gene")

rd[gs, ]

plotExprHeatmap(.catalyst(sim), gs, by = "cluster_id", 
    fun = "mean", scale = "last", q = 0,
    hm_pal = hcl.colors(10, "Lajolla"),
    row_anno = FALSE, col_dend = FALSE)

cs <- split(seq(ncol(sim)), sim$cluster)
es <- sapply(cs, function(.) rowMeans(logcounts(sim)[gs, .]))
pheatmap(t(es), scale = "column")

plot(hclust(dist(t(scale(sapply(cs, function(.) rowMeans(logcounts(ref)[, .])))))))
plot(hclust(dist(t(scale(sapply(cs, function(.) rowMeans(logcounts(sim)[gs, .])))))))

assay(ref, "cpm") <- as.matrix(calculateCPM(ref))
assay(sim, "cpm") <- as.matrix(calculateCPM(sim))

df <- .eval_grid(ref, sim, 
    x_fun = function(.) rowMeans(log2(assay(., "cpm")+1)),
    y_fun = function(.) rowVars(log2(assay(., "cpm")+1)), n = 100)

ggplot(df$data, aes(x, y, col = id)) + 
    geom_point() + 
    labs(
        x = NULL, 
        y = "Var(log2(CPM+1))") +

ggplot(df$diff, aes(x, y)) +
    geom_point() +
    geom_hline(yintercept = 0, col = "blue") +
    labs(
        x = "mean log2(CPM+1)", 
        y = "difference") +
    
    plot_layout(ncol = 1, guides = "collect") &
    theme_linedraw()

#.eval_ls <- function(ref, sim) {
    l <- list(ref = ref, sim = sim)
    l <- lapply(l, function(.) { .$lls <- log(colSums(counts(.))); .})
    
    vars <- list(k = "cluster", b = "batch")
    grps <- vars[vars %in% names(colData(ref))]
    if (length(grps) == 2) {
        grps <- c(grps, list(kb = unname(unlist(grps))))
    } else grps <- as.list(grps)
    
    l <- lapply(l, function(.) { .$foo <- "foo"; . })
    grps <- c(grps, list(g = "foo"))
    
    cd <- lapply(l, function(sce) data.table(data.frame(colData(sce))))
    cd <- lapply(cd, function(df) lapply(grps, function(by)
        split(df, by = by, sorted = TRUE, flatten = TRUE)))
    lls <- map_depth(cd, -2, "lls")
    
    res <- lapply(setNames(names(grps), names(grps)), function(g) {
        lapply(setNames(names(lls$ref[[g]]), names(lls$ref[[g]])), function(id) {
            if (length(lls$ref[[g]][[id]]) < 2) ks <- NA else
                ks <- suppressWarnings(ks.test(
                    lls$ref[[g]][[id]], 
                    lls$sim[[g]][[id]])$statistic)
            data.frame(stat = ks, row.names = NULL)
        }) %>% bind_rows(.id = "id")
    }) %>% bind_rows(.id = "group") %>%
        mutate(
            cluster = case_when(
                group == "k" ~ id,
                group == "b" ~ "GLOBAL",
                group == "g" ~ "GLOBAL",
                TRUE ~ gsub("\\..*", "", id)),
            batch = case_when(
                group == "b" ~ id,
                group == "k" ~ "GLOBAL",
                group == "g" ~ "GLOBAL",
                TRUE ~ gsub(".*\\.", "", id)))
    
    p <- ggplot(res, 
        aes(cluster, batch, fill = stat)) + 
        geom_tile(col = "white") + 
        scale_fill_gradientn("KS stat.",
            colors = hcl.colors(10, "Oslo"),
            limits = c(0, 1), na.value = "grey") + 
        coord_equal(expand = FALSE) + 
        theme_linedraw() + 
        theme(
            panel.grid = element_blank(),
            axis.text.x = element_text(angle = 45, hjust = 1))
#}