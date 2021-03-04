suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
    library(jsonlite)
})

# wcs <- list(metric = "cell_lls")
# args <- list(
#     con = "config/metrics.json",
#     res = list.files("results", "ks-Mer", full.names = TRUE))

pat <- ".*,(.*)\\.rds"
ids <- gsub(pat, "\\1", args$res)
names(args$res) <- ids

df <- lapply(args$res, readRDS) %>% 
    bind_rows(.id = "metric")

ggplot(df, aes(metric, stat, 
    shape = group, col = method)) +
    geom_path(position = position_dodge(0.5)) +
    geom_point(position = position_dodge(0.5)) +
    scale_y_continuous("KS statistic", limits = c(0, 1)) +
    .prettify("linedraw") 

ggsave(args$fig, p, width = 7.5, height = 5, units = "cm")

# res <- mutate(
#     readRDS(args$res),
#     foo = paste(group, id, sep = ";"))
# max <- ceiling(max(res$stat/0.25))*0.25
# 
# lab1 <- paste(wcs$datset, wcs$subset, sep = ";")
# lab2 <- fromJSON(args$con)[[wcs$metric]]$lab
# 
# p <- ggplot(res, aes(method, foo, fill = stat)) +
#     geom_tile(col = "white") +
#     scale_fill_viridis_c("KS statistic", 
#         limits = c(0, max),
#         breaks = seq(0, 1, 0.25)) + 
#     coord_equal(expand = FALSE) + 
#     .prettify("linedraw") + theme(
#         axis.title = element_blank(),
#         panel.border = element_blank(),
#         axis.text.x = element_text(angle = 45, hjust = 1)) +
#     labs(title = lab1, subtitle = lab2)
# 
# ggsave(args$fig, p, units = "cm",
#     width = 2*length(unique(res$method)), 
#     height = 2*length(unique(res$foo)))