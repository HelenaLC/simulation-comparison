


source(paste0("code/05-",wcs$type,"_qc-",wcs$metric,".R" ))

df <- data.frame(refset= wcs$refset, 
                 subset= names(wcs)[2], 
                 type = wcs$type, 
                 metric=wcs$metric, 
                 method = ifelse(is.null(wcs$method), "ref", wcs$method), 
                 qc)
print(head(df))

saveRDS(df, args$res)