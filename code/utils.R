# visualization ----

# + color palette
.pal <- c(
    reference = "black",
    muscat = "royalblue",
    BASiCS = "maroon",
    SPsimSeq = "tomato",
    splatter = "orange",
    scDesign = "gold",
    SymSim = "green",
    SPARSim = "blue",
    powsimR ="grey", 
    POWSC="chocolate")

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
    pat <- sprintf(".*,(.*)\\.rds")
    ids <- gsub(pat, "\\1", basename(sim))
    
    res <- lapply(c(ref, sim), readRDS)
    names(res) <- c("reference", ids)
    
    nan <- vapply(res, function(.) 
        isTRUE(is.na(.)), logical(1))
    if (all(nan)) {
        df <- NA
    } else {
        df <- bind_rows(res, .id = "method")
        df$method <- factor(df$method, names(.pal))
    }
    return(df)
}

# EVALUATION ----

# one-dimensional ----

# + Kolmogorov-Smirnov test

.ks <- function(x, y)
{
    z <- if (isTRUE(y == "pnorm")) 
        list(mean = mean(x), sd = sd(x))
    suppressWarnings(z <- do.call(ks.test, c(list(x, y), z)))
    res <- as.numeric(z$statistic)
    print("ks result")
    print(res)
    return(res)
}

# two-dimensional ----

# compute earth mover distance between two matrices ref$x,y and sim$x,y as a distibution over a two-dimensional grid
# ref and sim must have two columns (in each column one metric)

.emd <- function(x, y, n = 25) {
    stopifnot(is.numeric(n), length(n) == 1, n == as.integer(n))
    if (is.null(dim(x))) {
        # ONE-DIMENSIONAL
        # smoothing
        x <- density(x, n = n)$x
        y <- density(y, n = n)$x
        # compute EMD
        ws <- rep(1/n, n)
        x <- cbind(ws, x)
        y <- cbind(ws, y)
        emd(x, y)
    } else {
        # TWO-DIMENSIONAL
        if (!is.matrix(x)) x <- as.matrix(x)
        if (!is.matrix(y)) y <- as.matrix(y)
        # smoothing over common range
        rng <- c(
            range(c(x[, 1], y[, 1])),
            range(c(x[, 2], y[, 2])))
        x <- kde2d(x[, 1], x[, 2], n = n, lims = rng)
        y <- kde2d(y[, 1], y[, 2], n = n, lims = rng)
        # compute EMD
        emd2d(x$z, y$z)/n
    }
}

# two-dimensional Kolmogorov-Smirnov two-sample test
.ks2 <- function(x, y) Peacock.test::peacock2(x, y)

# utils ----

.split_cells <- function(x, i = c("cluster", "sample", "batch")){
    names(i) <- i <- intersect(i, names(colData(x)))
    cs <- c(
        list(global = list(foo = TRUE)),
        lapply(i, function(.) split(seq(ncol(x)), x[[.]])))

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
.calc_qc_for_splits <- function(x, metric_name, i = c("cluster", "sample", "batch"), FUN){
    
    cs <- .split_cells(x, i)
    
    res <- map_depth(cs, 2, function(.) {
        df <- data.frame(
            FUN(x[, .]), 
            row.names = NULL)
        names(df) <- metric_name
        return(df)
    })
    
    res <- .combine_res_of_splits(res)
    
    return(res)
}
