# args <- list(
#     rds = list.files("plts", "(rts|mbs).*\\.rds", full.names = TRUE),
#     pdf = "figs/rts_vs_mbs.pdf",
#     uts = "code/utils-plotting.R")

source(args$uts)
ps <- lapply(args$rds, readRDS)

pat <- ".*_([a-z])\\.rds"
reftyp <- gsub(pat, "\\1", basename(args$rds))
is <- split(seq_along(ps), reftyp)[c("n", "b", "k")]

ps <- lapply(is, \(i) {

    nm <- c("rts", "mbs")
    for (j in seq_along(nm)) {
        k <- grep(nm[[j]], args$rds[i])
        df <- paste0("df_", nm[[j]])
        assign(df, ps[i][[k]]$data)
    }
    
    i <- c("method", "dim", "n", j <- c("t", "mbs"))
    #f <- \(.) factor(., sort(as.numeric(as.character(unique(.)))))
    f <- \(.) as.numeric(as.character(.))
    df_rts <- df_rts %>% 
        filter(step == "overall") %>% 
        mutate(n = f(n)) %>% ungroup() %>% select(any_of(i)) 
    
    df_mbs <- df_mbs %>% 
        mutate(n = f(n)) %>% ungroup() %>% select(any_of(i)) 
    
    df <- full_join(
        df_rts, df_mbs, 
        by = setdiff(i, j)) %>% 
        filter(!is.na(t), !is.na(mbs))
    pal <- .methods_pal[levels(df$method)]
    
    p <- ggplot(df, aes(t, mbs, col = method, fill = method)) +
        scale_color_manual(values = pal) +
        scale_fill_manual(values = pal) +
        facet_grid(~ dim) +
        geom_point(alpha = 0.8) + 
        geom_path(size = 0.2) +
        scale_x_continuous("runtime (s)", limits = c(0, NA), trans = "sqrt") + 
        scale_y_continuous("memory usage (MBs)", limits = c(0, NA)) 
    
    .prettify(p) + theme(
        panel.grid.major = element_line(color = "grey", size = 0.2))
})

fig <- wrap_plots(ps, ncol = 1) +
    plot_annotation(tag_levels = "a") &
    theme(
        plot.margin = margin(),
        panel.spacing = unit(1, "mm"),
        legend.title = element_blank(),
        plot.tag = element_text(size = 9, face = "bold"))

ggsave(args$pdf, fig, width = 16, height = 16, units = "cm")
