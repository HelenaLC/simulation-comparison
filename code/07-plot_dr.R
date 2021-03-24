suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
    library(patchwork)
})

# wcs <- list(
#     refset = "Kang18.1015")
# 
# args <- list(
#     ref = sprintf("results/dr_ref-%s.rds", wcs$refset),
#     sim = list.files("results", sprintf("dr_sim-%s,.*\\.rds", wcs$refset), full.names = TRUE))

ref <- readRDS(args$ref)
sim <- lapply(args$sim, readRDS)

pat <- sprintf(".*-%s,(.*)\\.rds", wcs$refset)
ids <- gsub(pat, "\\1", basename(args$sim))

names(sim) <- ids
dat <- c(list(ref = ref), sim)
df <- bind_rows(dat, .id = "method")
df$method <- factor(df$method, names(.pal))

i <- c("lls", "cluster", "batch")
i <- intersect(i, names(df))

ps <- lapply(i, function(.) {
    ggplot(df, aes(TSNE1, TSNE2, col = .data[[.]])) +
        (if (length(i) == 1) facet_wrap(~ method, nrow = 2) else facet_grid(~ method)) +
        geom_point(size = 0.25, alpha = 0.25) +
        theme_linedraw(6) + theme(
            aspect.ratio = 1,
            panel.grid = element_blank(),
            axis.text = element_blank(),
            axis.ticks = element_blank(),
            axis.title = element_text(hjust = 0),
            legend.key.size = unit(0.5, "lines"),
            panel.border = element_rect(fill = NA),
            strip.text = element_text(color = "black"),
            strip.background = element_rect(fill = NA),
            legend.position = c(1, 0.5),
            legend.justification = c(0, 0.5),
            legend.margin = margin(l = 0.25, unit = "cm"),
            panel.spacing = unit(0.25, "cm")) +
        if (is.numeric(df[[.]])) {
            scale_color_viridis_c() 
        } else list(
            scale_color_brewer(palette = "Set1"),
            guides(col = guide_legend(override.aes = list(alpha = 1, size = 2))))
})

if (length(ps) > 1) {
    ps[-1] <- lapply(ps[-1], "+", theme(
        strip.text = element_blank(),
        strip.background = element_blank()))
    ps[-length(ps)] <- lapply(ps[-length(ps)], "+", theme(
        axis.title = element_blank()))
}

p <- wrap_plots(ps, ncol = 1)

if (length(i) == 1) {
    w <- 2*length(dat)+4
    h <- 8*length(i)
} else {
    w <- 4*length(dat)+4
    h <- 4*length(i)
}

ggsave(args$fig, p, width = w, height = h, units = "cm")