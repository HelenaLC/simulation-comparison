suppressPackageStartupMessages({
    library(dplyr)
    library(ggplot2)
    library(patchwork)
    library(RColorBrewer)
    library(tidyr)
    library(tidytext)
})

.read_res <- function(x) {
    df <- x %>% 
        lapply(readRDS) %>% 
        bind_rows() %>% 
        replace_na(list(method = "ref")) %>% 
        mutate(method = droplevels(factor(method, names(.methods_pal))))
    if ("id" %in% names(df))
        df <- mutate(df,
            group = relevel(factor(group), ref = "global"),
            id = case_when(group == "global" ~ "global", TRUE ~ id),
            id = relevel(factor(id), ref = "global"))
    if (any(grepl("^metric", names(df))))
        df <- mutate(df, across(starts_with("metric"), function(.)
            droplevels(factor(., names(.metrics_lab), .metrics_lab))))
    return(df)
}

# themes ----

.prettify <- function(plt, thm) 
{
    col <- !is.null(plt$labels$colour) && !is.numeric(plt$data[[plt$labels$colour]])
    fill <- !is.null(plt$labels$fill) && !is.numeric(plt$data[[plt$labels$fill]])
    
    plt <- plt + if (col && fill) { 
        tmp <- if (plt$labels$colour != plt$labels$fill) {
            guide_legend(order = 1, override.aes = list(alpha = 1, size = 2, stroke = 0.5, shape = 21))
        } else FALSE
        guides(
            col = tmp,
            fill = guide_legend(override.aes = list(alpha = 1, size = 2, col = NA, shape = 21)))
    } else if (col) { guides(
        col = guide_legend(override.aes = list(alpha = 1, size = 2, shape = 21)))
    } else if (fill) { guides(
        fill = guide_legend(override.aes = list(alpha = 1, size = 2)))
    }
    plt <- plt + 
        theme_linedraw(6) + theme(
            panel.grid = element_blank(),
            legend.key.size = unit(0.5, "lines"),
            strip.background = element_blank(),
            strip.text = element_text(color = "black"))
    return(plt + thm)
}

# colors ----

.groups_pal <- c(global = "grey40", batch = "grey80", cluster = "grey80")

pat <- ".*-sim_data-(.*)\\.R"
methods <- gsub(pat, "\\1", list.files("scripts", pat))
.methods_pal <- colorRampPalette(brewer.pal(8, "Set3"))(length(methods))
.methods_pal <- c(ref = "black", setNames(.methods_pal, methods))

pat <- ".*calc_qc-(.*)\\.R"
.metrics <- gsub(pat, "\\1", list.files("scripts", pat))
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
    cell_cor = "cell-to-cell correlation")

n <- 5
.metrics_pal <- c(
    setNames(hcl.colors(n*length(.gene_metrics), "Reds" )[seq(1, n*length(.gene_metrics), n)], .gene_metrics),
    setNames(hcl.colors(n*length(.cell_metrics), "Blues")[seq(1, n*length(.cell_metrics), n)], .cell_metrics))
names(.metrics_pal) <- .metrics_lab

pat <- ".*-stat_1d-(.*)\\.R"
.stats1d <- gsub(pat, "\\1", list.files("scripts", pat))
.stats1d_lab <- c(ks = "KS", ws = "W")

pat <- ".*-stat_2d-(.*)\\.R"
.stats2d <- gsub(pat, "\\1", list.files("scripts", pat))
.stats2d_lab <- c(emd = "EMD", ks2 = "KS")
