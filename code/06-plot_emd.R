suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
    library(matrixStats)
    library(tidyr)
})

# wcs <- list(stat_2d = "ks2")
# args <- list(res = list.files("results", paste0(wcs$stat_2d, "-"), full.names = TRUE))

pat <- ".*-(.*),(.*),(.*)\\.rds"
refset  <- gsub(pat, "\\1", basename(args$res))
metric1 <- gsub(pat, "\\2", basename(args$res))
metric2 <- gsub(pat, "\\3", basename(args$res))

res <- lapply(args$res, readRDS)
ns <- vapply(res, function(.) 
    ifelse(isTRUE(is.na(.)), 0, nrow(.)), 
    numeric(1))

df <- do.call(rbind, res)
df <- df[!rowAlls(is.na(df)), ]

df$refset <- rep(refset, ns)
df$metrics <- paste(
    rep.int(metric1, ns), 
    rep.int(metric2, ns), 
    sep = " vs. ")

df <- df %>% 
    group_by(refset, method, group, metrics) %>% 
    summarize_at("stat", mean) %>% 
    ungroup() %>%
    complete(refset, method, group, metrics,
        fill = list(emd = NA))

p <- ggplot(df, 
    aes(method, metrics, fill = stat)) +
    facet_grid(group ~ refset) +
    geom_tile(color = "black", width = 1, height = 1) +
    scale_fill_viridis_c(limits = c(0, NA), na.value = "grey95") +
    coord_equal(expand = FALSE) +
    theme_linedraw(6) + theme(
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        panel.grid = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(color = "black"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.key.size = unit(0.5, "lines"))

ggsave(args$fig, p, width = 15, height = 6, units = "cm")
