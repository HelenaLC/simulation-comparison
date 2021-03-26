suppressPackageStartupMessages({
  library(scater)
  library(scran)
  library(SingleCellExperiment)
  library(dreval)
  library(jsonlite)
  library(dplyr)
})
# dr <- readRDS("results/dr_sim-panc8.indrop_alpha,splatter.rds")
# x <- readRDS("data/02-sub/panc8.indrop_alpha.rds")

# x <- readRDS("data/02-sub/Kang18.1015.rds")
# dr <- readRDS("results/dr_ref-Kang18.1015.rds")


data_type <- fromJSON("config/subsets.json")[[wcs$datset]][[wcs$subset]][["type"]]

x <- readRDS(args$sce_ref)
x <- logNormCounts(x)

print("dim of sce")
print(dim(x))
numcol <- ncol(x)
dr_eval <- function(x, data_type){
  if(data_type=="k"){
    res <- dreval(x, refType = "assay", refAssay = "logcounts", labelColumn ="cluster")
  }else{
    if(data_type=="b"){
      res <- dreval(x, refType = "assay", refAssay = "logcounts", labelColumn ="batch")
    }else{
      res <- dreval(x, refType = "assay", refAssay = "logcounts")
    }
  }
  return(res$scores)
}

#df for the dimension reduction of the reference data set
dr <- readRDS(args$dr_ref)
print("dim of dr")
print(dim(dr))
reducedDims(x) <- list(TSNE=dr[,c("TSNE1","TSNE2")])

df <- dr_eval(x, data_type) %>%
       rename(., dr_method=Method) %>%
       mutate(., 
         method = "ref",
         group = "global", 
         id = "foo",
         refset = paste0(wcs$datset, ".", wcs$subset))

# df for the simulation datasets
for (sim in args$dr_sim) {
  dr <- readRDS(sim)
  print("dim of dr")
  print(dim(dr))
  method <- gsub(pattern=".*,(.*).rds", x=basename(sim), replacement = '\\1')
  print(method)
  # TBD : some methods do have different amount of cells... TODO: fix that
  if(nrow(dr) == numcol){
    reducedDims(x) <- list(TSNE=dr[,c("TSNE1","TSNE2")])
    res <- dr_eval(x, data_type) %>%
                rename(., dr_method=Method) %>%
                mutate(.,
                    method = method,
                    group = "global",
                    id = "foo",
                    refset = paste0(wcs$datset, ".", wcs$subset))
      df <- rbind(df, res)
      
  }
}



# 
# #dr for the dimension reduction of the reference data set
# dr <- readRDS(args$dr_ref)
# reducedDims(x) <- list(TSNE=dr[,c("TSNE1","TSNE2")])
# 
# if(data_type=="k"){
#   res <- dreval(x, refType = "assay", refAssay = "logcounts", labelColumn ="cluster")
# }else{
#   if(data_type=="b"){
#     res <- dreval(x, refType = "assay", refAssay = "logcounts", labelColumn ="batch")
#   }else{
#     res <- dreval(x, refType = "assay", refAssay = "logcounts")
#   }
# }
# res$scores
# df<- res$scores %>%
#     rename(., dr_method=Method) %>%
#     mutate(., 
#            method = ifelse(is.null(wcs$method), "ref", wcs$method),
#            group = "global", 
#            id = "foo",
#            refset = paste0(wcs$datset, ".", wcs$subset))
# 
# #df for the simulation datasets



head(df)
saveRDS(df, args$res)