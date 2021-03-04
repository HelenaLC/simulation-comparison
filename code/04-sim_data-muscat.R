source("~/Packages/foo/R/utils.R")
source("~/Packages/foo/R/utils-simData.R")

suppressPackageStartupMessages({
    library(ape)
    library(data.table)
    library(dplyr)
    library(edgeR)
    library(extraDistr)
    library(MASS)
    library(mvtnorm)
    library(phylobase)
    library(purrr)
    library(SingleCellExperiment)
})

# ref <- readRDS("data/03-est/Mereu20,CD4T,muscat.rds")
# x <- ref
# ng <- nrow(x)
# nc <- ncol(x)
# pde <- 0.1
# pdd <- diag(6)[1, ]
# ep <- dp <- 0.3
# dm <- 0.5
# kp <- sp <- bp <- gp <- NULL
# lfc <- list(family = "gamma", shape = 4, rate = 2)
# ke <- se <- be <- "mimic"

fun <- function(x, ng = nrow(x), nc = ncol(x),
    pde = 0.1, pdd = diag(6)[1, ], ep = 0.3, dp = 0.3, dm = 0.5,
    kp = NULL, sp = NULL, bp = NULL, gp = NULL, 
    lfc = list(family = "gamma", shape = 4, rate = 2),
    ke = c("mimic", "exact", "remove"),
    se = c("mimic", "exact", "remove"),
    be = c("mimic", "exact", "remove")) {
    
    ke <- se <- be <- "exact"
    
    # throughout this code...
    # k = cluster 
    # s = sample   
    # b = batch
    # g = group
    
    # check validity of input arguments
    ke <- match.arg(ke)
    se <- match.arg(se)
    be <- match.arg(be)
    eval(.setup)
    
    # sample NB parameters
    eval(.fit_os) # offsets
    eval(.fit_bs) # betas
    
    # impose hierarchical cluster structure
    if (nk > 1 && ke == "mimic") {
        # get logFCs between each pair of clusters
        bs_k <- cbind(0, rowData(x)$beta$cluster)
        names(bs_k)[1] <- setdiff(kids, names(bs_k))
        
        lfcs_k <- sapply(kids, function(i) lapply(kids, function(j)
            if (i == j) return(0) else mean(abs(bs_k[, i] - bs_k[, j]))))
        
        # hierarchical clustering on between-cluster logFCs
        hc <- hclust(as.dist(lfcs_k))
        tree <- as.phylo(hc)
        phylo <- as(tree, "phylo4")
        N <- 1 + (E <- nrow(tree$edge))
        
        # sample number of DE genes (nde) at each non-root node
        nde <- rdgamma(N-1, 8, 8/round(pde*ng/(N-1)))
        nde <- c(nde[seq(nk)], 0, if (nk < 3) NULL else nde[seq(nk+1, N-1)])
        
        # sample indices of DE genes at each node
        degs <- split(sample(gs, sum(nde)), rep.int(factor(seq(N)), nde))
        
        # sample logFCs proportional to branch length (bl)
        lfcs_degs <- lapply(seq(N), function(n) {
            # skip root node
            if (n == nk+1) return(NULL)
            # get branch length
            bl <- tree$edge.length[tree$edge[, 2] == n]
            bl <- bl/mean(tree$edge.length)
            pm <- sample(c(-1, 1), nde[n], TRUE)
            pm * rgamma(nde[n], 4, 4/(2*bl))
        })
        
        # get each node's descendants
        tips <- lapply(seq(N), function(n) descendants(phylo, n))
        
        # add logFCs to cluster-specific betas
        for (n in seq(N)) {
            if (n == nk+1) next # skip root node
            bs_n <- bs$k[degs[[n]], names(tips[[n]])]
            lfcs_n <- unlist(lfcs_degs[n])
            bs$k[degs[[n]], names(tips[[n]])] <- bs_n + lfcs_n
        }
    }

    # sample number of genes to simulate per DD category
    ndd <- vapply(kids, function(k)
        table(sample(cats, ng, TRUE, pdd)),
        numeric(length(cats)))
    
    # sample gene indices
    gi <- vapply(kids, function(k)
        split(gs, rep.int(cats, ndd[, k])),
        vector("list", length(cats)))
    
    # sample logFCs for DD genes
    dist <- get(paste0("r", lfc$family))
    dist_pars <- lfc[-grep("family", names(lfc))]
    lfcs_dd <- vapply(kids, function(k)
        lapply(unfactor(cats), function(c) {
            n <- ndd[c, k]
            if (c == "ee")
                return(rep(NA, n))
            # sample directions w/ equal prob. of up- & down regulation
            dirs <- sample(c(-1, 1), n, TRUE)
            lfcs <- do.call(dist, c(n, dist_pars))
            setNames(dirs*lfcs, gi[[c, k]])
        }), vector("list", length(cats)))
    
    ds <- setNames(rowData(x)$disp, gs)
    b0 <- setNames(rowData(x)$beta$beta0, gs)

    y <- mapply(function(k, b, s) {
        # get cell indices
        ci <- ci[[k]][[b]][[s]]
        nc <- vapply(ci, length, numeric(1))
        
        y <- lapply(unfactor(cats[ndd[, k] != 0]), function(c) {
            # get indices & number of genes
            ng <- length(gi <- gi[[c, k]])
            
            # get NB means
            ms <- lapply(gids, function(g) {
                bs <- rowSums(cbind(b0[gi],
                    bs$k[gi, k],  # cluster effect
                    bs$s[gi, s],  # sample effect
                    bs$b[gi, b])) # batch effect
                # mu = exp(beta) * lambda
                #    = exp(beta) * exp(offset)
                outer(exp(bs), exp(os[[k]][[b]][ci[[g]]]))
            })

            # impute DD
            if (c != "ee") {
                fcs <- 2^lfcs_dd[[c, k]]
                switch(c, 
                    ep = {
                        ms <- lapply(gids, function(g) {
                            i <- sample(nc[[g]], round(ep*nc[[g]]))
                            ms[[g]][, i] <- fcs*ms[[g]][, i]
                            ms[[g]]
                        })
                    },
                    de = {
                        gi <- split(gi, sample(gids, ng, TRUE))
                        ms <- lapply(gids, function(g) {
                            ms[[g]][gi[[g]], ] <- fcs[gi[[g]]]*ms[[g]][gi[[g]], ]
                            ms[[g]]
                        })
                    },
                    dp = {
                        gi <- split(gi, sample(gids, ng, TRUE))
                        for (g in gids) {
                            h <- setdiff(gids, g)
                            i <- sample(nc[[g]], round(dp*nc[[g]]))
                            j <- sample(nc[[h]], round((1-dp)*nc[[h]]))
                            ms[[g]][gi[[g]], i] <- fcs[gi[[g]]]*ms[[g]][gi[[g]], i]
                            ms[[h]][gi[[g]], j] <- fcs[gi[[g]]]*ms[[h]][gi[[g]], j]
                        }
                    },
                    db = {
                        gi <- split(gi, sample(gids, ng, TRUE))
                        for (g in gids) {
                            h <- setdiff(gids, g)
                            i <- sample(nc[[h]], round(0.5*nc[[h]]))
                            ms[[g]][gi[[g]],  ] <- 0.5*fcs[gi[[g]]]*ms[[g]][gi[[g]],  ]
                            ms[[h]][gi[[g]], i] <-     fcs[gi[[g]]]*ms[[h]][gi[[g]], i]
                        }
                    })
            }
            # sample counts
            y <- lapply(gids, function(g) {
                y <- rnbinom(ng*nc[[g]], rep(1/ds[gi], nc[[g]]), mu = ms[[g]])
                matrix(y, ng, nc[[g]], dimnames = list(gi, ci[[g]]))
            })
            do.call(cbind, y)
        })
        y <- do.call(rbind, y)
        y[gs, , drop = FALSE]
    }, 
        k = rep(kids, each = ns*nb),
        b = rep(bids, each = ns),
        s = rep(sids, nk*nb),
        SIMPLIFY = FALSE)
    y <- do.call(cbind, y)[, cs]
    
    gi <- data.frame(
        row.names = NULL, 
        gene = unlist(gi),
        cluster = rep.int(rep(kids, each = length(cats)), c(ndd)),
        category = rep.int(rep(cats, nk), c(ndd)),
        logFC = unlist(lfcs_dd))
    o <- order(as.numeric(gsub("[a-z]", "", gi$gene)))
    gi <- gi[o, ]; rownames(gi) <- NULL
    
    # construct feature metadata
    rd <- DataFrame(
        row.names = gs,
        beta = I(DataFrame(
            beta0 = b0,
            lapply(bs, I))))
    if (nk > 1 && ke == "mimic") {
        nodes <- mapply(function(n, gs) {
            ks <- list(names(tips[[n]]))
            I(rep(ks, nde[n]))
        }, n = seq(N), gs = degs)
        nodes <- unlist(nodes, recursive = FALSE)
        specs <- vapply(nodes, length, numeric(1))
        
        rd <- cbind(rd, DataFrame(
            is_de = gs %in% unlist(degs),
            specs = 0, nodes = NA, logFC = NA))
        rd[unlist(degs), "specs"] <- specs
        rd[unlist(degs), "nodes"] <- I(nodes)
        rd[unlist(degs), "logFC"] <- unlist(lfcs_degs)
    }
    
    if (nk == 1) cd$cluster <- NULL
    if (ns == 1) cd$sample <- NULL
    if (nb == 1) cd$batch <- NULL
    
    SingleCellExperiment(
        assays = list(counts = y),
        rowData = rd, colData = cd)
    # metadata = list(
    #     gene_info = gi))
}
