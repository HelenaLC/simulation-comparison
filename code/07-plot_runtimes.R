# wcs <- list(reftyp = "n")
# args <- list(
#     rds = sprintf("plts/rts_%s.rds", wcs$reftyp),
#     pdf = sprintf("plts/rts_%s.pdf", wcs$reftyp),
#     fun = "code/utils-plotting.R",
#     res = list.files("outs", sprintf("^rts_%s-", wcs$reftyp), full.names = TRUE))

source(args$fun)
res <- .read_res(args$res)

df <- res %>% 
    # drop SCRIP estimation for 'reftyp' other than 'n'
    # as there's none, it's just setting up parameters
    { if (wcs$reftyp != "n")
        mutate(., est = case_when(
            method == "SCRIP" ~ NA_real_,
            TRUE ~ est)) else . } %>%
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

# order methods by overall average across subsets
ms <- df %>% 
    filter(step == "overall") %>% 
    group_by(method) %>% 
    summarise_at("t", mean) %>% 
    arrange(t) %>% pull("method")
df$method <- factor(df$method, levels = ms)

pal <- .methods_pal[levels(df$method)]

lab <- parse(text = paste(
    sep = "~",
    sprintf("bold(%s)", LETTERS), 
    gsub("\\s", "~", names(pal))))

anno <- df %>% 
    group_by(step, dim) %>% 
    mutate(letter = LETTERS[match(method, levels(method))])

plt <- ggplot(df, aes(factor(n), t, 
    col = method, fill = method)) +
    facet_grid(step ~ dim, scales = "free") +
    geom_bar(
        width = 0.9,
        stat = "identity",
        position = "dodge") +
    geom_text(data = anno, 
        aes(label = letter, y = 0),
        size = 1.5, vjust = 2, color = "black",
        position = position_dodge(0.9)) + 
    scale_fill_manual(values = pal, labels = lab) +
    scale_color_manual(values = pal, labels = lab) +
    xlab(NULL) + scale_y_sqrt("runtime (s)", 
        expand = expansion(mult = c(0.2, 0.1)))

thm <- theme(
    axis.ticks.x = element_blank(),
    legend.title = element_blank(),
    legend.text = element_text(hjust = 0),
    panel.grid.major.y = element_line(color = "grey"))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 18, height = 9, units = "cm")
