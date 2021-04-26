source("scripts/utils-plotting.R")

fns <- c(
  "plots/qc_1d-Kang18,B.rds",
  "plots/qc_1d-CellBench,celseq.rds",
  "plots/dr-Zheng17,foo.rds")

ps <- lapply(fns, readRDS)

fig <- wrap_elements(ps[[1]]) /
  wrap_elements(ps[[2]]) /
  wrap_elements(ps[[3]]) +
  plot_layout(heights = c(1, 2, 1.5)) +
  plot_annotation(tag_level = "a") &
  theme(
    plot.margin = margin(), 
    legend.position = "right")

fnm <- "qc_dr.pdf"
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 16, height = 16, units = "cm")
