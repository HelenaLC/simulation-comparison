suppressPackageStartupMessages({
    library(SingleCellExperiment)
})

fun <- \()
{
    # bump timeout limit of 60 sec to 5 min
    # to assure download isn't interrupted
    options(timeout = max(300, getOption("timeout")))
    
    # get count data
    url <- "https://ndownloader.figshare.com/files/10756798?private_link=865e694ad06d5857db4b"
    dir <- dirname(fnm <- tempfile())
    download.file(url, fnm, quiet = TRUE)
    fns <- untar(fnm, list = TRUE)
    
    # read in counts
    sub <- grep("/MammaryGland.Virgin[0-9]", fns, value = TRUE)
    untar(fnm, files = sub, exdir = dir)
    ys <- lapply(file.path(dir, sub), \(.) {
        y <- read.csv(., sep = " ")
        as(as.matrix(y), "dgCMatrix")
    })
    
    # get shared features
    gs <- lapply(ys, rownames)
    gs <- Reduce(intersect, gs)
    
    # join & construct SCE
    y <- do.call(cbind, lapply(ys, \(.) .[gs, ]))
    x <- SingleCellExperiment(assays = list(counts = y))
    
    # get cell metadata
    url <- "https://ndownloader.figshare.com/files/11083451?private_link=865e694ad06d5857db4b"
    fnm <- tempfile()
    download.file(url, fnm, quiet = TRUE)
    cd <- read.csv(fnm)
    
    # drop cells w/o metadata
    i <- match(colnames(x), cd$Cell.name, nomatch = 0)
    x <- x[, i != 0]
    cd <- cd[i, ]
    
    # simplify annotations
    cluster <- gsub("\\(.*\\)$", "", cd$Annotation)
    
    # add cell metadata
    colData(x) <- DataFrame(
        tissue = cd$Tissue,
        batch = cd$Batch, 
        cluster)
    
    return(x)
}
