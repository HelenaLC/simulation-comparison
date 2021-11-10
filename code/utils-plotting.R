suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
    library(ggpubr)
    library(ggrastr)
    library(ggrepel)
    library(magrittr)
    library(patchwork)
    library(RColorBrewer)
    library(tidyr)
    library(tidytext)
})

.read_res <- function(x) {
    df <- bind_rows(lapply(x, readRDS)) %>% 
        replace_na(list(method = "ref")) %>% 
        mutate(method = droplevels(factor(method, names(.methods_pal))))
    if (all(c("datset", "subset") %in% names(df)))
        df <- mutate(df, refset = paste(datset, subset, sep = ","))
    if ("id" %in% names(df))
        df <- mutate(df,
            group = relevel(factor(group), ref = "global"),
            id = case_when(group == "global" ~ "global", TRUE ~ id),
            id = relevel(factor(id), ref = "global"))
    if (all(c("refset", "group") %in% names(df)))
        df <- group_by(df, refset) %>% 
            mutate(.group = as.character(group)) %>% 
            mutate(reftyp = ifelse(any(.group == "batch"), "b", 
                ifelse(any(.group == "cluster"), "k", "n")),
                reftyp = factor(reftyp, c("n", "b", "k"))) %>% 
            select(-.group)
    if (sum(grepl("method", names(df))) > 1)
        df <- rename(df, sim_method = method)
    if (any(grepl("^metric", names(df))))
        df <- mutate(df, across(
            starts_with("metric"), 
            ~droplevels(factor(.x, 
                levels = names(.metrics_lab), 
                labels = .metrics_lab))))
    return(df)
}

.filter_res <- function(df) df %>% 
    mutate(
        .metric = names(.metrics_lab)[
            match(metric, .metrics_lab)],
        across(c(group, id), as.character)) %>% 
    filter(
        # keep everything for type 'n'
        reftyp == "n" |
        # keep all groupings for global summaries, 
        # gene-level (-correlations), cell-level 
        # (-log-library size & cell detection frequency
        .metric %in% .none_metrics |
        .metric %in% setdiff(.gene_metrics, "gene_cor") |
        .metric %in% setdiff(.cell_metrics, c("cell_lls", "cell_frq")) |
        # for gene-gene correlation, keep global only
        (group == id & .metric == "gene_cor") |
        # for log-library size & cell detection 
        # frequency, keep group-level results only 
        (group != id & grepl("cell_(lls|frq)", .metric))) %>% 
    ungroup() %>% 
    select(-.metric) %>% 
    mutate(across(c(metric, method), droplevels))

# repeatedly average statistics, e.g., 
# across groups, subsets, datsets, etc. 
.avg <- \(df, n) {
    .fun <- \(df) summarise_at(df, "stat", mean, na.rm = TRUE)
    res <- Reduce(\(df, foo) .fun(df), seq(n), init = df, accumulate = TRUE)
   ungroup(res[[n + 1]])
}

.prettify <- function(plt, thm = NULL, base_size = 6) 
{
    col <- !is.null(plt$labels$colour) && !is.numeric(plt$data[[plt$labels$colour]])
    fill <- !is.null(plt$labels$fill) && !is.numeric(plt$data[[plt$labels$fill]])
    
    plt <- plt + if (col && fill) { 
        tmp <- if (plt$labels$colour != plt$labels$fill) {
            guide_legend(order = 1, override.aes = list(alpha = 1, size = 2, stroke = 0.5, shape = 21))
        } else "none"
        guides(
            col = tmp,
            fill = guide_legend(override.aes = list(alpha = 1, size = 2, col = NA, shape = 21)))
    } else if (col) { guides(
        col = guide_legend(override.aes = list(alpha = 1, size = 2, shape = 21)))
    } else if (fill) { guides(
        fill = guide_legend(override.aes = list(alpha = 1, size = 2)))
    }
    plt <- plt + 
        theme_linedraw(base_size) + theme(
            panel.grid = element_blank(),
            legend.key.size = unit(0.5, "lines"),
            strip.background = element_blank(),
            strip.text = element_text(color = "black"))
    return(plt + thm)
}

# aesthetics ----

.groups_pal <- c(global = "grey40", batch = "grey80", cluster = "grey80", group = "grey80")

pat <- ".*-sim_data-(.*)\\.R"
methods <- gsub(pat, "\\1", list.files("code", pat))
.methods_pal <- colorRampPalette(brewer.pal(12, "Paired"))(length(methods))
.methods_pal <- c(ref = "black", setNames(.methods_pal, methods))

pat <- ".*calc_qc-(.*)\\.R"
.metrics <- gsub(pat, "\\1", list.files("code", pat))
.none_metrics <- c("gene_pve", "cell_cms", "cell_sw")
.metrics <- setdiff(.metrics, .none_metrics)
.gene_metrics <- grep("gene", .metrics, value = TRUE)
.cell_metrics <- grep("cell", .metrics, value = TRUE)

.metrics_lab <- c(
    gene_avg = "average of logCPM",
    gene_var = "variance of logCPM",
    gene_cv  = "coefficient of variation",
    gene_frq = "gene detection frequency",
    gene_cor = "gene-to-gene correlation",
    cell_lls = "log-library size",
    cell_frq = "cell detection frequency",
    cell_cor = "cell-to-cell correlation",
    cell_ldf = "local density factor",
    cell_pcd = "cell-to-cell distance",
    cell_knn = "KNN occurences",
    gene_pve = "percent variance explained",
    cell_cms = "cell-specific mixing score",
    cell_sw = "silhouette width")

n <- 3
.metrics_pal <- c(
    setNames(hcl.colors(n*length(.gene_metrics), "Reds" )[seq(1, n*length(.gene_metrics), n)], .gene_metrics),
    setNames(hcl.colors(n*length(.cell_metrics), "Blues")[seq(1, n*length(.cell_metrics), n)], .cell_metrics),
    setNames(brewer.pal(1+length(.none_metrics), "Greens")[-1], .none_metrics))
names(.metrics_pal) <- .metrics_lab

pat <- ".*-stat_1d-(.*)\\.R"
.stats1d <- gsub(pat, "\\1", list.files("code", pat))
.stats1d_lab <- c(ks = "KS", ws = "W")

pat <- ".*-stat_2d-(.*)\\.R"
.stats2d <- gsub(pat, "\\1", list.files("code", pat))
.stats2d_lab <- c(emd = "EMD", ks2 = "KS")
