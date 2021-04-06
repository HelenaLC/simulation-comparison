suppressPackageStartupMessages({
    library(ggplot2)
    library(RColorBrewer)
})

# themes ----

.prettify <- list(
    guides(
        col = guide_legend(override.aes = list(alpha = 1, size = 2)),
        fill = guide_legend(override.aes = list(alpha = 1, size = 2))),
    theme_linedraw(6),
    theme(
        panel.grid = element_blank(),
        legend.key.size = unit(0.5, "lines"),
        strip.background = element_blank(),
        strip.text = element_text(color = "black"))
)

# colors ----

methods <- gsub(".*-(.*)\\.R", "\\1", list.files("code", "sim_data-"))
.methods_pal <- colorRampPalette(brewer.pal(8, "Set3"))(length(methods))
.methods_pal <- c(ref = "black", setNames(.methods_pal, methods))

pat <- ".*-(.*)\\.R"
gene_metrics <- paste0("gene.", gsub(pat, "\\1", list.files("code", "gene_qc")))
cell_metrics <- paste0("cell.", gsub(pat, "\\1", list.files("code", "cell_qc")))

.metrics_pal <- c(
    setNames(hcl.colors(length(gene_metrics), "Reds"), gene_metrics),
    setNames(hcl.colors(length(cell_metrics), "Blues"), cell_metrics))

.metrics_lab <- c(
    gene.avg = "average of logCPM",
    gene.var = "variance of logCPM",
    gene.cv  = "coefficient of variation",
    gene.frq = "gene detection frequency",
    gene.cor = "gene-to-gene correlation",
    cell.lls = "log-library size",
    cell.frq = "cell detection frequency",
    cell.cor = "cell-to-cell correlation",
    cell.pve = "Percent Variance Explained",
    cell.sil = "silhouette width")
