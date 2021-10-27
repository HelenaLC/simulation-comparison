# args <- list(
#     rds = "plts/rts_b.rds",
#     pdf = "plts/rts_b.pdf",
#     fun = "code/utils-plotting.R",
#     res = list.files("outs", "^rts_b-", full.names = TRUE))

source(args$fun)
res <- .read_res(args$res)

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

pal <- .methods_pal[levels(df$method)]

lab <- parse(text = paste(
    sep = "~",
    sprintf("bold(%s)", LETTERS), 
    gsub("\\s", "~", names(pal))))

anno <- df %>% 
    group_by(step, dim) %>% 
    #filter(n == min(n)) %>% 
    mutate(letter = LETTERS[match(method, levels(method))])

plt <- ggplot(df, aes(factor(n), t, 
    col = method, fill = method)) +
    facet_grid(step ~ dim, scales = "free") +
    geom_point() +
    geom_path(aes(group = method)) +
    geom_label_repel(
        data = anno, aes(label = letter), 
        col = "white", segment.colour = "grey", size = 1.5) +
    scale_fill_manual(values = pal, labels = lab) +
    scale_color_manual(values = pal, labels = lab) +
    scale_x_reordered(NULL) +
    scale_y_log10("runtime(s)", expand = expansion(mult = 0.1))

plt <- ggplot(df, aes(factor(n), t, 
    col = method, fill = method)) +
    facet_grid(step ~ dim, scales = "free") +
    geom_bar(
        width = 0.9, 
        stat = "identity", 
        position = "dodge") +
    geom_text(data = anno, 
        aes(label = letter, y = 0.1),
        size = 1.5, color = "black",
        position = position_dodge(0.9)) + 
    scale_fill_manual(values = pal, labels = lab) +
    scale_color_manual(values = pal, labels = lab) +
    scale_x_reordered(NULL) +
    scale_y_log10("runtime(s)", expand = expansion(mult = 0.1))

thm <- theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    legend.title = element_blank(),
    legend.text = element_text(hjust = 0),
    panel.grid.major.y = element_line(color = "grey"))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 16, height = 9, units = "cm")
