suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(x) {
  args <- list(
    ngenes = x$pars$totalG,
    estParamRes = x$pars,
    nsims = 1,  
    p.G = 1,
    setup.seed = 1234)
  
  l <- if (x$type == "n") {
    list(
      n1 = x$pars$totalS, 
      n2 = 2, # has to be at least 2
      p.DE = 0,
      pLFC = 0)
  } else {
    list(
      n1 = x$n1, 
      n2 = x$n2, 
      p.DE = x$markers$pDE, 
      pLFC = x$markers$logFC)
  }
  args <- c(args, l)
  setup <- do.call(Setup, args)
  sim <- simulateDE(
    SetupRes = setup,
    Normalisation = "scran",
    DEmethod = "DESeq2",
    Counts = TRUE,
    NCores = NULL,
    verbose = TRUE)
  
  y <- sim$Counts[[1]][[1]]
  if (x$type == "n") {
    # remove group 2 cells
    y <- y[, -c(1, 2)]
    SingleCellExperiment(
      assays = list(counts = y))
  } else {
    SingleCellExperiment(
      assays = list(counts = y),
      colData = x$colData)
  }
}

