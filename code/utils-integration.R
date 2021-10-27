.cms_ldf <- \(df) df %>% 
    group_by(refset, sim_method) %>% 
    mutate(
        # center around 0
        cms = cms - 0.5,
        # scale to range 1
        ldf = ldf / diff(range(ldf)),
        # center around 0
        ldf = ldf - min(ldf) - 0.5)

.bcs <- \(df, n = 1) {
    stopifnot(any(n == c(1, 2)))
    .avg <- \(df) summarise(df,
        across(c(cms, ldf), mean),
        .groups = "drop_last")
    df <- df %>% 
        group_by(refset, sim_method, batch_method, batch) %>% 
        # average across cells
        .avg()
    if (n == 2)
        # average across batches
        df <- df %>% .avg()
    # batch correction score
    df %>% mutate(bcs = abs(cms) + abs(ldf))
}

.batch_labs <- c(
    cms = "CMS*", bcs = "BCS",
    ldf = expression(Delta~"LDF*"))