suppressPackageStartupMessages({
    library(dplyr)
    library(MASS)
    library(tidyr)
})

df <- readRDS(args$dat)
if (is.null(df)) {
    saveRDS(NULL, args$res)
    quit()
}

# currently excluding "t" 
fs <- c(
    beta = "beta", 
    cauchy = "cauchy", 
    chisq = "chi-squared", 
    exp = "exponential", 
    gamma = "gamma", 
    geom = "geometric", 
    lnorm = "lognormal", 
    logis = "logistic", 
    nbinom = "negative binomial", 
    norm = "normal", 
    pois = "Poisson", 
    weibull = "weibull")

funs <- lapply(fs, function(f) 
    function(x) list(tryCatch(
        fitdistr(x, f)$estimate, 
        error = function(e) e)))

df <- df %>% 
    group_by(group, id, metric) %>% 
    summarise_at("value", list) %>% 
    rowwise() %>% 
    mutate_at("value", funs)

df <- pivot_longer(df,
    cols = intersect(names(fs), names(df)),
    names_to = "density",
    values_to = "params") %>% 
    rowwise() %>% 
    filter(!inherits(params, "error")) %>% 
    mutate(sample = list(do.call(
        get(paste0("r", density)), 
        c(n = 1e3, as.list(params))))) %>% 
    mutate(stat = ks.test(value, sample)$statistic) %>% 
    mutate(.before = 1, data.frame(wcs))

saveRDS(df, args$res)