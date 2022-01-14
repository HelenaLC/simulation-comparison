# args <- list(
#     pdf = "plts/memory.pdf",
#     fun = "code/utils-plotting.R",
#     res = list.files("logs", ".*\\.txt", full.names = TRUE))

source(args$fun)
res <- lapply(args$res, read.table, header = TRUE)
mbs <- do.call(rbind, res)[["max_rss"]]

# get metadata from output names
# rts_{reftyp}-{datset},{subset},
# {method},{ngs},{ncs},{rep}.rds
ss <- strsplit(basename(gsub("\\.txt", "", args$res)), ",")
reftyp <- gsub("rts_([a-z])-.*", "\\1", sapply(ss, .subset, 1))
refset <- paste(sep = ",",
    gsub(".*-", "", sapply(ss, .subset, 1)),
    sapply(ss, .subset, 2))
vars <- seq(3, 6)
names(vars) <- c("method", "ngs", "ncs", "rep")
vars <- lapply(vars, \(.) sapply(ss, .subset, .))

df <- data.frame(mbs, reftyp, refset, vars) %>% 
    pivot_longer(
        values_to = "n",
        names_to = "dim",
        cols = c("ngs", "ncs")) %>% 
    filter(n != "x") %>% 
    group_by(dim) %>%
    mutate(n = factor(n, sort(as.numeric(unique(n))))) %>%
    ungroup() %>%
    mutate(
        dim = factor(dim,
            levels = c("ngs", "ncs"),
            labels = c("# genes", "# cells")),
        method = droplevels(factor(method, names(.methods_pal)))) %>% 
    group_by(method, dim, n) %>%
    summarise_at("mbs", mean)

pal <- .methods_pal[levels(df$method)]
lab <- parse(text = paste(
    sep = "~",
    sprintf("bold(%s)", LETTERS), 
    gsub("\\s", "~", names(pal))))
anno <- mutate(df, letter = LETTERS[
    match(method, levels(method))])    

plt <- ggplot(df, aes(factor(n), mbs, 
    col = method, fill = method)) +
    facet_grid(~ dim, scales = "free") +
    geom_bar(
        width = 0.9,
        stat = "identity",
        position = "dodge") +
    geom_text(data = anno, 
        aes(label = letter, y = -250),
        size = 1.5, color = "black",
        position = position_dodge(0.9)) + 
    scale_fill_manual(values = pal, labels = lab) +
    scale_color_manual(values = pal, labels = lab) +
    xlab(NULL) + scale_y_continuous(
        "memory usage (MBs)",
        limits = c(-500, 4e3),
        expand = c(0, 0))

thm <- theme(
    axis.ticks.x = element_blank(),
    legend.title = element_blank(),
    legend.text = element_text(hjust = 0),
    panel.grid.major.y = element_line(color = "grey"))

fig <- .prettify(plt, thm)

saveRDS(fig, args$rds)
ggsave(args$pdf, fig, width = 18, height = 9, units = "cm")