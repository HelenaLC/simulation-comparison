# visualization ----

# + color palette
.pal <- c(
    ref = "black",
    muscat = "royalblue",
    BASiCS = "maroon",
    dyngen = "coral",
    ESCO = "brown2",
    scDD = "yellowgreen",
    scDesign = "gold",
    scDesign2 = "orange",
    SEGIO = "seagreen4",
    SPARSim = "blue",
    splatter = "brown",
    SPsimSeq = "tomato",
    SymSim = "green",
    POWSC = "chocolate",
    powsimR ="grey")

# theme for quality control plots
.prettify <- function(theme = NULL, ...) 
{
    if (is.null(theme)) theme <- "classic"
    base <- paste0("theme_", theme)
    base <- getFromNamespace(base, "ggplot2")
    base(base_size = 6) + theme(
        panel.grid = element_blank(),
        legend.key.size = unit(0.5, "lines"),
        strip.background = element_blank(),
        strip.text = element_text(color = "black"),
        axis.text = element_text(color = "black"))
}

# make SCE compatible with CATALYST
.catalyst <- function(x)
{
    df <- data.frame(
        foo = seq(ncol(x)), 
        meta20 = x$cluster)
    metadata(x)$cluster_codes <- df
    x$cluster <- NULL
    x$cluster_id <- seq(ncol(x))
    
    old <- c("sample", "group")
    new <- c("sample_id", "condition")
    i <- match(old, names(colData(x)), nomatch = 0)
    names(colData(x))[i] <- new[i != 0]
    
    i <- match("logcounts", assayNames(x))
    if (!is.na(i)) assayNames(x)[i] <- "exprs"

    return(x)
}

# quality control ----

# + read in QC results 

.read_res <- function(ref, sim)
{
    suppressPackageStartupMessages({
        library(dplyr)
    })
    
    pat <- sprintf(".*,(.*)\\.rds")
    ids <- gsub(pat, "\\1", basename(sim))
    
    res <- lapply(c(ref, sim), readRDS)
    names(res) <- c("ref", ids)
    
    nan <- vapply(res, is.null, logical(1))
    if (all(nan)) {
        df <- NULL
    } else {
        df <- bind_rows(res, .id = "method")
        df$method <- factor(df$method, names(.pal))
        df$group <- relevel(factor(df$group), "global")
    }
    return(df)
}

# utilities ----

.split_cells <- function(sce, 
    i = c("global", "cluster", "batch"))
{
    names(j) <- j <- intersect(i, names(colData(sce)))
    cs <- lapply(j, function(.) split(seq(ncol(sce)), sce[[.]]))
    if ("global" %in% i)
        cs <- c(list(global = list(foo = seq(ncol(sce)))), cs)
    return(cs)
    
}

.combine_res_of_splits <- function(res){
    res <- map_depth(res, 1, bind_rows, .id = "id")
    res <- bind_rows(res, .id = "group")
    return(res)
}

# split genes by group = "cluster","batch", "sample". 
# Then per group calculate the qc with the FUN function(which is a metric)
# returns a dataframe with cols:  group | id | metric_name
.calc_qc <- function(sce, fun, 
    n_genes = NULL, n_cells = NULL, 
    groups = c("global", "cluster", "batch"))
{
    suppressPackageStartupMessages({
        library(dplyr)
        library(purrr)
    })
    if (is.null(groups)) {
        groups <- eval(formals(.calc_qc)$groups)
    } else {
        groups <- match.arg(groups, several.ok = TRUE)
    }
    # split cells into groups
    idx <- .split_cells(sce, groups)
    # downsample to at most 'g' genes
    if (!is.null(n_genes)) {
        n_genes <- min(n_genes, nrow(sce))
        gs <- sample(nrow(sce), n_genes)
        sce <- sce[gs, ]
    }
    # downsample to at most 'c' cells per group
    if (!is.null(n_cells)) {
        idx <- map_depth(idx, -1, ~{
            n_cells <- min(n_cells, length(.x))
            sample(length(.x), n_cells)
        })
    }
    # compute QC metric per group
    res <- map_depth(idx, 2, ~{
        data.frame(
            row.names = NULL, 
            value = fun(sce[, .x]))
    })
    # join into single table
    res <- map_depth(res, 1, bind_rows, .id = "id")
    res <- bind_rows(res, .id = "group")
    if (nrow(res) == 0) return(NULL)
    res <- mutate(res, .before = "value",
        group.id = paste(group, id, sep = "."))
}

