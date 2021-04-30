source(args$fun)

est <- .read_res(args$est)
sim <- .read_res(args$sim)

df <- list(
    estimation = est, 
    simulation = sim) %>% 
    bind_rows(.id = "step") %>% 
    filter(!is.na(runtime)) %>% 
    group_by(step, datset, subset, method) %>% 
    summarize(
        .groups = "drop",
        runtime = runtime / sum(c(n_genes, n_cells)))

df <- df %>% 
    group_by(datset, subset, method) %>% 
    summarize(
        .groups = "drop",
        runtime = sum(runtime, na.rm = TRUE)) %>% 
    mutate(step = "total") %>% 
    bind_rows(df)

# round y-axis to nearest 0.1
max <- ceiling(max(df$runtime)*10)/10

plt <- ggplot(df, 
    aes(x = reorder_within(method, runtime, step), 
        y = runtime, col = method, fill = method)) +
    facet_wrap(~ step, nrow = 1, scales = "free_x") +
    geom_point(
        position = position_dodge(width = 0.5),
        shape = 21, alpha = 0.25, size = 1) + 
    stat_summary(fun.data = mean_se, size = 0.25, show.legend = FALSE) +
    scale_fill_manual(values = .methods_pal) +
    scale_color_manual(values = .methods_pal) +
    scale_y_continuous(
        "runtime per gene & cell (s)", 
        limits = c(0, max), breaks = seq(0, max, 0.1))

thm <- theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank())

fig <- .prettify(plt, thm)
ggsave(args$plt, fig, width = 12, height = 6, units = "cm")
