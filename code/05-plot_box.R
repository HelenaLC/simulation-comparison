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
dfs <- lapply(dfs, function(df)
    data.frame(df)[args$var])
df <- bind_rows(dfs, .id = "id")
df$id <- factor(df$id, names(dfs))

pal <- brewer.pal(length(ids), "Set1")
pal <- c(ref = "black", setNames(pal, ids))

ps <- lapply(args$var, function(.) {
    ggplot(df, 
        aes_string("id", ., fill = "id", col = "id")) +
        geom_boxplot(
            size = 0.25, outlier.size = 0.25,
            alpha = 0.25, key_glyph = "point") +
        guides(fill = guide_legend(
            override.aes = list(alpha = 1, size = 2))) +
        scale_fill_manual(NULL, values = pal) +
        scale_color_manual(NULL, values = pal) +
        .thm_qc() + 
        # labs(
        #     x = NULL,
        #     y = "detection frequency",
        #     title = "dataset: pacn8, subset: indrop_alpha") +
        theme(
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank())
})

saveRDS(ps, args$ggp)
pdf(args$pdf, width = 5/2.54, height = 4/2.54, onefile = TRUE)
for (p in ps) print(p); dev.off()
