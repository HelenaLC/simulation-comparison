# suppressPackageStartupMessages({
#     library(SingleCellExperiment)
# })
# 
# x <- readRDS("data/raw/Kang18.rds")
# 
# # average (avg) vs. variance (var) of log CPM
# cpm <- edgeR::cpm(assay(x))
# log_cpm <- log2(cpm + 1)
# avg <- rowMeans(log_cpm)
# var <- rowVars(log_cpm)
# frq <- rowMeans(assay(x) == 0)

df <- data.frame(avg, var, frq)
df <- df[df$frq != 0, ]

ggplot(df, aes(avg, var, fill = sqrt(..ndensity..))) +
    geom_hex(bins = 100) +
    scale_fill_gradientn(colors = rev(hcl.colors(9, "spectral"))) +
    theme_linedraw() + 
    theme(panel.grid = element_blank()) + 
    labs(
        x = "mean log(CPM + 1)",
        y = "Var log(CPM + 1)")

ggplot(df, aes(avg, var)) +
    geom_bin2d(bins = 100) +
    geom_smooth(col = "red") +
    #geom_point(size = 0.5, alpha = 0.5, shape = 16) + 
    scale_x_continuous(limits = range(df$avg)) +
    scale_y_continuous(limits = range(df$var)) +
    theme_linedraw() +
    theme(panel.grid = element_blank()) + 
    labs(
        x = "mean log(CPM + 1)",
        y = "Var log(CPM + 1)")
