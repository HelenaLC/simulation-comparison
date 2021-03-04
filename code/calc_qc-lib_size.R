suppressPackageStartupMessages({
    library(dplyr)
    library(purrr)
    library(SingleCellExperiment)
})

x <- readRDS("data/raw/Kang18.rds")
y <- log(colSums(assay(x)))

ids <- names(colData(x))
ids <- c(as.list(ids), asplit(combn(ids, 2), 2))
idx <- lapply(ids, function(.) 
{
    cd <- colData(x)[, c(.), drop = FALSE]
    split(seq(ncol(x)), as.list(cd))
})
names(idx) <- sapply(ids, paste, collapse = ".")
idx$global <- list(seq(ncol(x)))

.ks <- function(.) suppressWarnings(ks.test(
    x = ., y = "pnorm", mean = mean(.), sd = sd(.)))

df <- map_depth(idx, -1, function(.) {
    if (length(.) < 10)
        return(NULL)
    z <- .ks(y[.])
    data.frame(
        stat = z$statistic,
        pval = z$p.value,
        row.names = NULL)
}) %>% 
    map(bind_rows) %>% 
    bind_rows(.id = "group") 

# order groups by decreasing average statistic
lvls <- df %>% 
    group_by(group) %>% 
    summarize_at("stat", mean) %>% 
    arrange(desc(stat)) %>% 
    pull("group")
labs <- gsub("\\.", "\n", lvls)
df$group <- factor(df$group, lvls, labs)

ggplot(df, aes(group, stat)) + 
    geom_boxplot() +
    geom_text(
        data = count(df, group), 
        aes(y = 0.5, label = sprintf("(n=%s)", n))) +
    scale_y_continuous(limits = c(0, 0.5)) +
    labs(x = NULL, y = "KS statistic") +
    theme_linedraw() +
    theme(
        aspect.ratio = 2/3, 
        panel.grid = element_blank()) +
    ggtitle("Normality of log-library sizes")
