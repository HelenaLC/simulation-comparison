# wcs <- list(ngs = "x", ncs = 325, rep = 3)
# args <- list(
#     sce = "data/02-sub/Mereu20,CD4T.rds",
#     est = "code/03-est_pars-SCRIP.R",
#     sim = "code/04-sim_data-SCRIP.R")

suppressPackageStartupMessages({
    library(R.utils)
    library(SingleCellExperiment)
})

# set seed to current rep(licate) for reproducibility
set.seed(as.numeric(wcs$rep))

# read in dataset
x <- readRDS(args$sce)

# if down-sampling cells, use all 
# genes & store NA in output data.frame
if (wcs$ngs == "x") {
    wcs$ngs <- NA 
    ngs <- nrow(x) 
} else wcs$ngs <- ngs <- as.numeric(wcs$ngs)

# if down-sampling genes, use all 
# cells & store NA in output data.frame
if (wcs$ncs == "x") {
    wcs$ncs <- NA 
    ncs <- ncol(x) 
} else wcs$ncs <- ncs <- as.numeric(wcs$ncs)

# downsample number of genes / cells
x <- x[
    sample(nrow(x), ngs), 
    sample(ncol(x), ncs)]

sink(tempfile()) # suppress printing...

# set time limit (s) until timeout
t <- 1e4

# time estimation 
source(args$est)
est <- withTimeout(
    {
    tryCatch(
        system.time(y <- fun(x))[[3]],
        error = function(e) e)
    }, 
    timeout = t, 
    onTimeout = "warning")

if (is.character(est)) {
    # timed out
    est <- t
} else if (inherits(est, "error")) {
    # Inf if estimation failed
    est <- Inf
} else if (is.null(y)) {
    # NA if included in simulation
    est <- NA_real_
    # pass SCE to simulation
    y <- x
}

# time simulation
source(args$sim)
sim <- withTimeout(
    {
    tryCatch(
        system.time(fun(y))[[3]],
        error = function(e) e)
    }, 
    timeout = t, 
    onTimeout = "warning")

if (is.character(sim)) {
    # timed out
    sim <- t
} else if (inherits(sim, "error")) {
    # Inf if estimation failed
    sim <- Inf
} else if (is.null(sim)) {
    # NA if included in simulation
    sim <- NA_real_
}

sink() # ...until here

# construct table including wildcards (wcs),
# timing of est(imation) & sim(ulation), 
# and number of genes/cells (ng/cs)
res <- data.frame(wcs, est, sim, row.names = NULL)

# ...and write to .rds
saveRDS(res, args$res)