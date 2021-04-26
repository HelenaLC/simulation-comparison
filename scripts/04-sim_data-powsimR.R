suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(x){
  
  if(is.null(x$type)){
    setup <- Setup(ngenes = x$param$totalG, 
                   estParamRes = x$param, 
                   nsims = 1,
                   p.DE = 0.1, pLFC = 1, p.G = 1, # default
                   n1=c(x$param$totalS), 
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
    sce <- SingleCellExperiment(list(counts=sim))
    return(sce)
  }else{

    setup <- Setup(ngenes = x$param$totalG,
                  estParamRes = x$param,
                  nsims = 1,
                  p.DE = 0.1, pLFC = 1, p.G = 1, # default
                  p.B=x$estimate$pDE, bLFC=x$estimate$mean_logFC, #estimated from ref set
                  n1=c(x$n1),
                  n2=c(x$n2),
                  setup.seed = 1234)
    
    sim <- simulateDE(SetupRes=setup,
                      Normalisation = "scran",
                      DEmethod = "DESeq2",
                      Counts = TRUE,
                      NCores = NULL,
                      verbose = TRUE)

    sim <- as.data.frame(sim$Counts[[1]])
    # group <- stringi::stri_sub(colnames(sim), -5)
    # group <- data.frame(a = group)
    # colnames(group) <- x$type
    sce <- SingleCellExperiment(list(counts=sim), colData = x$colData)
    # return(sce)
  }
 
  
  # sim <- simulateDE(SetupRes=setup,
  #                   Normalisation = "scran",
  #                   DEmethod = "DESeq2",
  #                   Counts = TRUE,
  #                   NCores = NULL,
  #                   verbose = TRUE)
  # 
  # sim <- as.data.frame(sim$Counts[[1]])
  # sim <- sim[,c(-1,-2)] # removing the two entries of group n2
  # # colnames(as.data.frame(sim$Counts$`200vs200`))
  # sim <- SingleCellExperiment(list(counts=sim))
  # #stringi::stri_sub(colnames(as.data.frame(sim$Counts$`200vs200`)), -5)
  # return(sim)
}

