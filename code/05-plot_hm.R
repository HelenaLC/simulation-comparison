suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
    library(purrr)
    library(RColorBrewer)
})

# ref <- "results/qc-panc8,indrop_alpha.rds"
# sim <- list.files("results", "alpha,", full.names = TRUE)

(fns <- list(ref = args$ref, sim = args$sim))
res <- map_depth(fns, 2, readRDS)
dfs <- lapply(res, map, "gene")

pat <- ".*,(.*)\\.rds"
ids <- gsub(pat, "\\1", basename(fns$sim))

names(dfs$ref) <- "ref"
names(dfs$sim) <- ids

dfs <- Reduce(c, dfs)
dfs <- lapply(dfs, data.frame)
df <- bind_rows(dfs, .id = "id")
df$id <- factor(df$id, names(dfs))

df$group <- ifelse(df$id == "ref", "ref", "sim")
dfs <- split(df, df$group)

names(metrics) <- metrics <- args$var
res <- lapply(metrics, function(i) {
    group_by(dfs$sim, id) %>% 
        summarize(
            .groups = "drop",
            stat = .ks(!!sym(i), dfs$ref[[i]]))
}) %>% bind_rows(.id = "metric")

p <- ggplot(res, aes(id, metric, fill = stat)) +
    geom_tile(col = "black") + 
    scale_fill_viridis_c("KS stat.", 
        direction = -1, option = "E") +
    coord_equal(expand = FALSE) +
    theme_linedraw(6) + theme(
        axis.title = element_blank(),
        legend.key.size = unit(0.5, "lines"),
        axis.text.x = element_text(angle = 45, hjust = 1))

saveRDS(p, args$ggp)
ggsave(args$pdf, p, width = 5, height = 4, units = "cm")