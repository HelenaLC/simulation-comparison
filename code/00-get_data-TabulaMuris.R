suppressPackageStartupMessages({
    library(ExperimentHub)
    library(SingleCellExperiment)
})

fun <- \()
{
    eh <- ExperimentHub()
    q <- query(eh, "TabulaMurisDroplet")
    x <- eh[[q$ah_id]]
    
    x <- x[, x$mouse_id == "3-F-56"]
    x <- x[, !is.na(x$cell_ontology_class)]
    
    cd <- data.frame(
        tissue = x$tissue,
        cluster = x$cell_ontology_class)
    colData(x) <- DataFrame(cd)
    rowData(x) <- NULL
    
    return(x)
}