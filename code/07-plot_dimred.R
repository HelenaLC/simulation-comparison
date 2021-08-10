# wcs <- list(reftyp = "k")
# args <- list(
#     fun = "code/utils-plotting.R",
#     res = list.files("outs", "dr_ref", full.names = TRUE),
#     pdf = sprintf("figs/dimred_%s.pdf", wcs$reftyp))

source(args$fun)

dfs <- args$res %>%
    lapply(readRDS) %>%
    bind_rows() %>%
    mutate(
        refset = paste(datset, subset, sep = ","),
        type = ifelse(!is.na(batch), "b", ifelse(!is.na(cluster), "k", "n"))) %>% 
    filter(type == wcs$reftyp) %>% 
    group_split(refset) 

# number of columns
n <- 3 

# get variable to color by
# - log-library size (lls) for type n
# - batch for type b, cluster for type k
col <- switch(wcs$reftyp, n = "lls", b = "batch", k = "cluster")

fig <- lapply(seq_along(dfs), \(i) {
    plt <- ggplot(dfs[[i]], aes_string(
        "TSNE1", "TSNE2", col = col, fill = col)) +
        geom_point_rast(size = 0.1, alpha = 0.2) +
        (if (col == "lls") scale_color_viridis_c()) +
        guides(fill = "none") + ggtitle(dfs[[i]]$refset[1]) 
    thm <- theme(
        aspect.ratio = 1,
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.title = element_blank(),
        legend.justification = c(0, 0.5),
        plot.title = element_text(hjust = 0.5),
        axis.title.x = if (i > length(dfs) - n) element_text() else element_blank(),
        axis.title.y = if (i %% n != 1) element_blank() else element_text(angle = 90))
    .prettify(plt, thm)
}) %>% wrap_plots(ncol = n)

ggsave(args$pdf, fig, width = 16, height = 4*length(dfs)/n, units = "cm")
