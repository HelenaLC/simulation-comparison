suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(param){
  setup <- Setup(ngenes = param$totalG, 
                estParamRes = param, 
                nsims = 1,
                p.DE = 0.1, pLFC = 1, p.G = 1, # default
                n1=c(param$totalS), 
                n2=c(2), # has to be at least 2 otherwise it does not work, 
                setup.seed = 1234)
  
  sim <- simulateDE(SetupRes=setup,
                    Normalisation = "scran",
                    DEmethod = "DESeq2",
                    Counts = TRUE,
                    NCores = NULL,
                    verbose = TRUE)
  
  sim <- as.data.frame(sim$Counts[[1]])
  sim <- sim[,c(-1,-2)] # removing the two entries of group n2
  sim <- SingleCellExperiment(list(counts=sim))
  return(sim)
}

