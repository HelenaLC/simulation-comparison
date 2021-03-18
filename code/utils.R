# visualization ----

# + color palette
.pal <- c(
    reference = "black",
    muscat = "royalblue",
    BASiCS = "maroon",
    SPsimSeq = "tomato",
    splatter = "orange",
    scDesign = "gold",
    SymSim = "green")

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
    
    df <- bind_rows(res, .id = "method")
    df$method <- factor(df$method, names(.pal))
    return(df)
}

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

# + grid evaluation

# compute average difference between y 
# at each of n grid points along x
# ref/sim: two-column data.frame of x & y 
#          statistics for ref/sim dataset

.dy <- function(ref, sim, n = 1e3) 
{
    # split x into n chunks
    l <- list(ref = ref, sim = sim)
    df <- bind_rows(l, .id = "foo")
    df$n <- ceiling(order(df$x)/(nrow(df)/n))

    # compute average difference at each grid point
    group_by(df, n, foo) %>% 
        summarise_at(c("x", "y"), mean) %>% 
        group_by(n) %>% filter(n() > 1) %>% 
        summarise(x = mean(x), dy = diff(y))
}

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
# .emd <- function(ref, sim){
#    
#     x_ref <- as.matrix(ref[ ,1])
#     y_ref <- as.matrix(ref[ ,2])
#     x_sim <- as.matrix(sim[ ,1])
#     y_sim <- as.matrix(sim[ ,2])
#     lims <- c(
#         range(c(x_ref, x_sim)),
#         range(c(y_ref, y_sim)))
#     
#     d_ref <- kde2d(x_ref, y_ref, 50, lims = lims)
#     d_sim <- kde2d(x_sim, y_sim, 50, lims = lims)
#     
#     emd <- emd2d(d_ref$z, d_sim$z, dist = "euclidean")
#     return(emd)
# }


# simulation ----

# + utils ----

# don't know if this function is used..
# .split_cells <- function(x, by) 
# {
#     if (is(x, "SingleCellExperiment")) x <- colData(x)
#     cd <- data.frame(x[by], check.names = FALSE)
#     cd <- data.table(cd, i = rownames(x)) %>% 
#         split(by = by, sorted = TRUE, flatten = FALSE)
#     map_depth(cd, length(by), "i")
# }

#
.split_cells <- function(x){
    i <- c("cluster", "sample", "batch")
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
.calc_qc_for_splits <- function(x, metric_name, FUN){
    
    cs <- .split_cells(x)
    
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

# + globals ----

cats <- c("ee", "ep", "de", "dp", "dm", "db")
names(cats) <- cats <- factor(cats, levels = cats)

# + setup ---

.setup <- expression({
    nk <- ifelse(is.null(x$cluster), 1, nlevels(x$cluster))
    ns <- ifelse(is.null(x$sample), 1, nlevels(x$sample))
    nb <- ifelse(is.null(x$batch), 1, nlevels(x$batch))
    
    gs <- paste0("gene", sprintf(sprintf("%%0%sd", nchar(ng)), seq_len(ng)))
    cs <- paste0("cell", sprintf(sprintf("%%0%sd", nchar(nc)), seq_len(nc)))
    
    names(kids) <- kids <- { if (nk == 1) "foo" else levels(x$cluster) }
    names(sids) <- sids <- { if (ns == 1) "foo" else levels(x$sample)  }
    names(bids) <- bids <- { if (nb == 1) "foo" else levels(x$batch)   }
    names(gids) <- gids <- paste0("group", seq_len(2))
    
    if (is.null(kp)) { if (nk == 1) kp <- 1 else kp <- tabulate(x$cluster)/ncol(x) }
    if (is.null(sp)) { if (ns == 1) sp <- 1 else sp <- tabulate(x$sample)/ncol(x) }
    if (is.null(bp)) { if (nb == 1) bp <- 1 else bp <- tabulate(x$batch)/ncol(x) }
    if (is.null(gp)) gp <- rep(0.5, 2)
    
    # sample cell metadata
    cd <- data.frame(
        row.names = cs,
        cluster = factor(sample(kids, nc, TRUE, kp), kids),
        batch = factor(sample(bids, nc, TRUE, bp), bids),
        sample = factor(sample(sids, nc, TRUE, sp), sids),
        group = factor(sample(gids, nc, TRUE, gp), gids))
    
    # split cell indices
    dt <- data.table(i = cs, cd)
    ci <- split(dt, by = names(cd), 
        sorted = TRUE, flatten = FALSE)
    ci <- map_depth(ci, -2, "i")
})

# + offsets ----

.fit_os <- expression({
    df <- data.frame(colData(x))
    vars <- c("cluster", "batch")
    groups <- intersect(vars, names(df))
    if (length(groups) == 2) {
        groups <- c(groups, list(groups))
    } else groups <- as.list(groups)
    groups <- c(groups, list(TRUE))
    
    .ks <- function(.) {
        if (length(.) < 10) return(Inf)
        suppressWarnings(ks.test(., "pnorm", mean = mean(.), sd = sd(.))$statistic)
    }
    funs <- list(mean = mean, sd = sd, stat = .ks)
    
    stat <- lapply(groups, function(.) 
        summarise_at(
            group_by(df, .dots = .), 
            "offset", funs)
    ) %>% bind_rows() 
    
    if (length(missing <- setdiff(vars, groups)) != 0)
        for (. in missing) stat[[.]] <- NA
    
    os <- lapply(kids, function(k) {
        lapply(bids, function(b) {
            fit <- filter(stat, 
                is.na(batch) & cluster == k | 
                is.na(cluster) & batch == b |
                is.na(cluster) & is.na(batch)) %>% 
                slice_min(stat, n = 1) %>% 
                `[`(c("mean", "sd"))
            nc <- length(cs <- unlist(ci[[k]][[b]]))
            setNames(do.call(rnorm, c(nc, fit)), cs)
        })
    })
})

# + betas ----

.fit_bs <- expression({
    b0 <- rowData(x)$beta$beta0
    bs <- list(
        k = if (nk == 1) {
            matrix(0, ng, 1, dimnames = list(gs, kids))
        } else {
            bs <- as.matrix(rowData(x)$beta$cluster)
            switch(ke, 
                exact = {
                    bs <- cbind(0, bs)    
                },
                mimic = {
                    bs <- rmvnorm(ng, colMeans(bs), cov(bs)) 
                    bs <- cbind(0, bs)
                },
                remove = {
                    bs <- replicate(nk, rowMeans(cbind(0, bs)))
                })
            dimnames(bs) <- list(gs, kids)
            bs
        },
        s = if (ns == 1) {
            bs <- matrix(0, ng, 1, dimnames = list(gs, sids))
        } else {
            bs <- as.matrix(rowData(x)$beta$sample)
            switch(se, 
                exact = {
                    bs <- cbind(0, bs)
                },
                mimic = {
                    bs <- rmvnorm(ng, colMeans(bs), cov(bs))
                    bs <- cbind(0, bs)
                },
                remove = {
                    bs <- replicate(ns, rowMeans(cbind(0, bs)))
                })
            dimnames(bs) <- list(gs, sids)
            bs
        },
        b = if (nb == 1) {
            matrix(0, ng, 1, dimnames = list(gs, bids))
        } else {
            bs <- as.matrix(rowData(x)$beta$batch)
            bs <- switch(be,
                exact = {
                    bs <- cbind(0, bs)
                },
                mimic = {
                    bs <- rmvnorm(ng, colMeans(bs), cov(bs))
                    bs <- cbind(0, bs)
                },
                remove = {
                    bs <- replicate(nb, rowMeans(cbind(0, bs)))
                })
            dimnames(bs) <- list(gs, bids)
            bs
        })
})

