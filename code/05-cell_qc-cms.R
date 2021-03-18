suppressPackageStartupMessages({
  library(CellMixS)
  library(purrr)
  library(dplyr)
  library(SingleCellExperiment)
})
x <- readRDS(args$sce)


if("batch" %in% names(colData(x))){
qc_func <- function(x){return(cms(x, k=2, group="batch", assay_name = "counts"))} #TODO: chose good params

cs <- .split_cells(x, i=c("cluster", "sample")) # hope this works, couldn't test it since all datasets so far only have "batch" no cluster nor sample
res <- map_depth(cs, 2, function(.) {
    qc_res <- qc_func(x[, .])
    df <- data.frame(
      cell_cms=qc_res$cms,
      cell_cms_smooth=qc_res$cms_smooth,
      row.names = NULL)
    return(df)
})
qc <- .combine_res_of_splits(res)
}else{
  qc <- NA
}


