suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(x) {
  y <- counts(x) 
  if (!is.matrix(y))
    y <- as.matrix(y)

  if(ncol(colData(x)) == 0){
    # type n
    e <- estimateParam(
      countData = y, 
      RNAseq = "singlecell",
      Protocol = "UMI",
      Distribution = "NB",
      Normalisation = "scran",
      GeneFilter = 0.05, # default
      SampleFilter = 3,
      NCores = 1,
      verbose = FALSE)
    list(param = e)
  }else{
    #type g
    type <- names(colData(x))
    group <- data.frame(group = colData(x)[[type]], row.names = colnames(x)) # note: needs cell names(colnames) 
    e <- estimateParam(
      countData = y, 
      batchData = group,
      RNAseq = "singlecell",
      Protocol = "UMI",
      Distribution = "NB",
      Normalisation = "scran",
      GeneFilter = 0.05,# default
      SampleFilter = 3,
      NCores = 1,
      verbose = FALSE)
    f <- .find_markers(x, group = type)
    df <- colData(x)
    list(param = e, type = type, estimate = f, n1 = table(colData(x)[[type]])[[1]], n2 =table(colData(x)[[type]])[[2]], colData = df)
  }
}
