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

# utilities ----

.split_cells <- function(sce, 
    i = c("global", "cluster", "batch"))
{
    names(j) <- j <- intersect(i, names(colData(sce)))
    cs <- lapply(j, function(.) {
        ids <- droplevels(factor(sce[[.]]))
        split(seq(ncol(sce)), ids)
    })
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
    # downsample to at most 'n_genes' in total
    if (!is.null(n_genes)) {
        n_genes <- min(n_genes, nrow(sce))
        gs <- sample(nrow(sce), n_genes)
        sce <- sce[gs, ]
    }
    # downsample to at most 'n_cells' per group
    if (!is.null(n_cells)) {
        idx <- map_depth(idx, -1, ~{
            n_cells <- min(n_cells, length(.x))
            sample(.x, n_cells)
        })
    }
    # compute QC metric per group
    res <- map_depth(idx, -1, ~{
        data.frame(
            row.names = NULL, 
            value = fun(sce[, .x]))
    })
    # join into single table
    res <- map_depth(res, 1, bind_rows, .id = "id")
    res <- bind_rows(res, .id = "group")
    if (nrow(res) != 0) return(res)
}

# group can be either "cluster" or "batch"
.find_markers <- function(sce, group)
{
    y <- scuttle::normalizeCounts(sce, log = TRUE)
    g <- droplevels(factor(sce[[group]]))
    
    mgs <- scran::findMarkers(y, groups = g, pval.type = "all")
    mgs <- lapply(mgs, function(.) {
        df <- data.frame(.)
        df <- df[, c("FDR", "summary.logFC")]
    })
    df <- do.call(rbind, mgs)
    
    sig <- df$FDR < 0.05
    pDE <- sum(sig) / nrow(df)
    logFC <- df$summary.logFC[sig]
    pUp <- mean(logFC > 0)
    pDown <- mean(logFC < 0)
    logFC <- mean(abs(logFC))

    list(pDE = pDE, logFC = logFC, pDown = pDown, pUp = pUp)
}

# Hungarian algorithm
# (LM Weber, Aug '16)

.hungarian <- function(clus_algorithm, clus_truth) {
  
  # number of detected clusters
  n_clus <- length(table(clus_algorithm))
  
  # remove unassigned cells (NA's in clus_truth)
  unassigned <- is.na(clus_truth)
  clus_algorithm <- clus_algorithm[!unassigned]
  clus_truth <- clus_truth[!unassigned]
  if (length(clus_algorithm) != length(clus_truth)) 
      warning("vector lengths are not equal")
  
  tbl_algorithm <- table(clus_algorithm)
  tbl_truth <- table(clus_truth)
  
  # detected clusters in rows, true populations in columns
  pr_mat <- re_mat <- F1_mat <- matrix(NA, nrow = length(tbl_algorithm), ncol = length(tbl_truth))
  
  for (i in 1:length(tbl_algorithm)) {
    for (j in 1:length(tbl_truth)) {
      i_int <- as.integer(names(tbl_algorithm))[i]  # cluster number from algorithm
      j_int <- as.integer(names(tbl_truth))[j]  # cluster number from true labels
      
      true_positives <- sum(clus_algorithm == i_int & clus_truth == j_int, na.rm = TRUE)
      detected <- sum(clus_algorithm == i_int, na.rm = TRUE)
      truth <- sum(clus_truth == j_int, na.rm = TRUE)
      
      # calculate precision, recall, and F1 score
      precision_ij <- true_positives / detected
      recall_ij <- true_positives / truth
      F1_ij <- 2 * (precision_ij * recall_ij) / (precision_ij + recall_ij)
      
      if (F1_ij == "NaN") F1_ij <- 0
      
      pr_mat[i, j] <- precision_ij
      re_mat[i, j] <- recall_ij
      F1_mat[i, j] <- F1_ij
    }
  }
  
  # put back cluster labels (note some row names may be missing due to removal of unassigned cells)
  rownames(pr_mat) <- rownames(re_mat) <- rownames(F1_mat) <- names(tbl_algorithm)
  colnames(pr_mat) <- colnames(re_mat) <- colnames(F1_mat) <- names(tbl_truth)
  
  # match labels using Hungarian algorithm applied to matrix of F1 scores (Hungarian
  # algorithm calculates an optimal one-to-one assignment)
  
  # use transpose matrix (Hungarian algorithm assumes n_rows <= n_cols)
  F1_mat_trans <- t(F1_mat)
  
  if (nrow(F1_mat_trans) <= ncol(F1_mat_trans)) {
    # if fewer (or equal no.) true populations than detected clusters, can match all true populations
    labels_matched <- clue::solve_LSAP(F1_mat_trans, maximum = TRUE)
    # use row and column names since some labels may have been removed due to unassigned cells
    labels_matched <- as.numeric(colnames(F1_mat_trans)[as.numeric(labels_matched)])
    names(labels_matched) <- rownames(F1_mat_trans)
    
  } else {
    # if fewer detected clusters than true populations, use transpose matrix and assign
    # NAs for true populations without any matching clusters
    labels_matched_flipped <- clue::solve_LSAP(F1_mat, maximum = TRUE)
    # use row and column names since some labels may have been removed due to unassigned cells
    labels_matched_flipped <- as.numeric(rownames(F1_mat_trans)[as.numeric(labels_matched_flipped)])
    names(labels_matched_flipped) <- rownames(F1_mat)
    
    labels_matched <- rep(NA, ncol(F1_mat))
    names(labels_matched) <- rownames(F1_mat_trans)
    labels_matched[as.character(labels_matched_flipped)] <- as.numeric(names(labels_matched_flipped))
  }
  
  # precision, recall, F1 score, and number of cells for each matched cluster
  pr <- re <- F1 <- n_cells_matched <- rep(NA, ncol(F1_mat))
  names(pr) <- names(re) <- names(F1) <- names(n_cells_matched) <- names(labels_matched)
  
  for (i in 1:ncol(F1_mat)) {
    # set to 0 if no matching cluster (too few detected clusters); use character names 
    # for row and column indices in case subsampling completely removes some clusters
    pr[i] <- ifelse(is.na(labels_matched[i]), 0, pr_mat[as.character(labels_matched[i]), names(labels_matched)[i]])
    re[i] <- ifelse(is.na(labels_matched[i]), 0, re_mat[as.character(labels_matched[i]), names(labels_matched)[i]])
    F1[i] <- ifelse(is.na(labels_matched[i]), 0, F1_mat[as.character(labels_matched[i]), names(labels_matched)[i]])
    
    n_cells_matched[i] <- sum(clus_algorithm == labels_matched[i], na.rm = TRUE)
  }
  
  # means across populations
  mean_pr <- mean(pr)
  mean_re <- mean(re)
  mean_F1 <- mean(F1)
  
  return(list(n_clus = n_clus, 
              pr = pr, 
              re = re, 
              F1 = F1, 
              labels_matched = labels_matched, 
              n_cells_matched = n_cells_matched, 
              mean_pr = mean_pr, 
              mean_re = mean_re, 
              mean_F1 = mean_F1))
}