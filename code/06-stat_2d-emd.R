fun <- function(x, y, n = 25) {
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
        x <- MASS::kde2d(x[, 1], x[, 2], n = n, lims = rng)
        y <- MASS::kde2d(y[, 1], y[, 2], n = n, lims = rng)
        # compute EMD
        emdist::emd2d(x$z, y$z)/n
    }
}