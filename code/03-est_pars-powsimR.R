suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(x) {
  y <- counts(x) 
  if (!is.matrix(y))
    y <- as.matrix(y)
  z <- estimateParam(
    countData = y,
    RNAseq = "singlecell",
    Protocol = "UMI",
    Distribution = "NB",
    Normalisation = "scran",
    GeneFilter = 0,
    SampleFilter = Inf,
    NCores = 1,
    verbose = FALSE)
  Setup(
    ngenes = z$totalG,
    estParamRes = z,
    n1 = z$totalS, 
    n2 = 2, # has to be at least 2
    p.DE = 0,
    pLFC = 0,
    p.G = 1,
    nsims = 1,  
    setup.seed = 1234)
}
