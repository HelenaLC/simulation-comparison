suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(param){
  setup<- Setup(estParamRes = param, nsims = 1,
             p.DE = 0.1, pLFC = 1, p.G = 1, n1=c(20,50,100), n2=c(30,60,120), # per default,check n1,n2!
             setup.seed = 1234)
  
  sim <- simulateDE(SetupRes=setup,
                    Normalisation = "scran",
                    DEmethod = "DESeq2",
                    Counts = TRUE,
                    NCores = NULL,
                    verbose = TRUE)
  sim <- sim$Counts[[1]] # gives a list (lengt(n1)=3) of counts
  sim <- SingleCellExperiment(list(counts=as.data.frame(sim)))
  return(sim)
}

