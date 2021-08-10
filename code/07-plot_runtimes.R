# args <- list(
#     res = list.files("outs", "^rts_b-", full.names = TRUE),
#     rds = "plts/rts_b.rds",
#     pdf = "plts/rts_b.pdf",
#     fun = "code/utils.R")

source(args$fun)

res <- bind_rows(lapply(args$res, readRDS)) %>%
    mutate(method = droplevels(factor(method, names(.methods_pal))))

df <- res %>% 
    # sum up estimation & simulation timings
    rowwise() %>% 
    mutate(tot = {
        if (is.finite(est)) {
            if (is.finite(sim)) {
                est + sim # both available
            } else est # only estimation
        } else if (is.finite(sim)) {
            sim # only simulation
        } else NA # neither available
    }) %>% 
    ungroup() %>% 
    pivot_longer(
        values_to = "n",
        names_to = "dim",
        cols = c("ngs", "ncs")) %>%
    pivot_longer(
        values_to = "t",
        names_to = "step",
        cols = c("est", "sim", "tot")) %>%
    mutate(
        dim = factor(dim,
            levels = c("ngs", "ncs"),
            labels = c("# genes", "# cells")),
        step = factor(step,
            levels = c("est", "sim", "tot"),
            labels = c("estimation", "simulation", "overall"))) %>%
    filter(!is.na(n), !is.na(t), is.finite(t)) %>%
    group_by(method, step, dim, n) %>%
    summarise_at("t", mean)

pal <- .methods_pal
pal <- pal[levels(df$method)]

plt <- ggplot(df, aes(factor(n), t, col = method, fill = method)) +
    facet_grid(step ~ dim, scales = "free") +
    geom_point(
        position = position_dodge(width = 0.25),
        shape = 21, size = 2, col = "white", stroke = 0.2) +
    guides(fill = guide_legend(override.aes = list(stroke = 0))) +
    geom_vline(
        lty = 3, size = 0.25,
        xintercept = seq(2, 4) - 0.5) +
    scale_fill_manual(values = pal) +
    scale_color_manual(values = pal) +
    scale_y_log10("runtime(s)") +
    xlab(NULL)

thm <- theme(
    panel.grid.major = element_line(size = 0.2, color = "lightgrey"))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")
