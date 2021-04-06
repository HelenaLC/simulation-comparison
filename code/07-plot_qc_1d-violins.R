suppressPackageStartupMessages({
    library(dplyr)
})

source(args$utils)

# wcs <- list(refset = "CellBench")
# args <- list(
#     ref = list.files("results", sprintf("qc_ref-%s", wcs$refset), full.names = TRUE),
#     sim = list.files("results", sprintf("qc_sim-%s", wcs$refset), full.names = TRUE))
# 
df <- args[c("ref", "sim")] %>%
    unlist() %>%
    lapply(readRDS) %>%
    bind_rows()
# sub <- df[sample(nrow(df), 2e3), ]

if (all(df$group == "global")) {
    x <- "method"
    nrow <- 2
    height <- 6
    thm <- theme(axis.text.x = element_blank())
} else {
    x <- "id"
    nrow <- 3
    height <- 9
    thm <- theme(axis.text.x = element_text(angle = 30, hjust = 1))
}
width <- 15
y <- "value"
col <- "method"

df <- mutate(df, 
    type.metric = factor(type.metric,
        levels = names(.metrics_lab), 
        labels = .metrics_lab),
    id = case_when(group == "global" ~ group, TRUE ~ id),
    id = relevel(factor(id), ref = "global"),
    method = droplevels(factor(method, names(.methods_pal))))

p <- ggplot(df, 
    aes_string(x, y, col = col)) +
    facet_wrap(~ type.metric, nrow = nrow, scales = "free_y") +
    geom_violin(
        key_glyph = "point",
        fill = NA, width = 0.8, size = 0.2) +
    geom_boxplot(
        fill = NA, width = 0.8, size = 0.2, 
        show.legend = FALSE, outlier.size = 0.1) +
    scale_color_manual(NULL, values = .methods_pal) +
    .prettify + thm + theme(
        axis.title = element_blank(),
        axis.ticks.x = element_blank())

ggsave(args$fig, p, width = width, height = height, units = "cm")
