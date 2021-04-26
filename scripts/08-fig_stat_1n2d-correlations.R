source("scripts/utils-plotting.R")

fns <- c(
  "plots/stat_1d-correlation.rds",
  "plots/stat_2d-correlation.rds")

ps <- lapply(fns, readRDS)
ps[[2]]$facet$params$nrow <- 1

fig <- wrap_plots(ps, ncol = 1) +
  plot_layout(heights = c(2.5, 1)) +
  plot_annotation(tag_levels = "a") &
  theme(
    plot.margin = margin(), 
    plot.tag = element_text(face = "bold", size = 9))

fnm <- "stat1n2d-correlations.pdf"
fnm <- file.path("figures", fnm)
ggsave(fnm, fig, width = 16, height = 12, units = "cm")
