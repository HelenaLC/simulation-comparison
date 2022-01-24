import json
import itertools

configfile: "config.yaml"
R = config["R"]

# get datasets, subsets & methods
DATSETS = glob_wildcards("code/00-get_data-{x}.R").x
SUBSETS = json.loads(open("meta/subsets.json").read())
METHODS = json.loads(open("meta/methods.json").read())

# keep only subsets for which get_data script exists
SUBSETS = {d:s for d,s in SUBSETS.items() if d in DATSETS}

# keep only methods for which est_pars & sim_data script exists
METHODS = {m:t for m,t in METHODS.items() if
	m in glob_wildcards("code/03-est_pars-{x}.R").x and
	m in glob_wildcards("code/04-sim_data-{x}.R").x}

# combine datsets & subsets into single refset
# storing its 'type' (one of 'n', 'b', 'k')
REFSETS = {"{},{}".format(d,s): t
	for d in SUBSETS.keys()
	for s in SUBSETS[d].keys()
	for t in SUBSETS[d][s]["type"]}
REFTYPS = ["n", "b", "k"]

# combine refsets & methods into simsets 
# if the method supports the refset's 'type'
SIMSETS = ["{},{}".format(r,m)
	for r in REFSETS.keys()
	for m in METHODS.keys()
	if REFSETS[r] in METHODS[m]]
SIMSETS = {s: REFSETS.get(r)
	for s in SIMSETS
	for r in REFSETS
	if r in s}

# get quality control summaries
METRICS = glob_wildcards("code/05-calc_qc-{x}.R").x

# pair up gene-/cell-level summaries, respectively (excluding
# correlations, PVE, CMS, PC distance & silhouette width)
GENE_METRICS = [m for m in METRICS if "gene_" in m]
CELL_METRICS = [m for m in METRICS if "cell_" in m]

GENE_EXCLUDE = ["gene_pve", "gene_cor"]
CELL_EXCLUDE = ["cell_sw", "cell_cms", "cell_ldf", "cell_pcd", "cell_cor"]

GENE_METRICS = [m for m in GENE_METRICS if m not in GENE_EXCLUDE]
CELL_METRICS = [m for m in CELL_METRICS if m not in CELL_EXCLUDE]

METRIC_PAIRS = \
	list(itertools.combinations(GENE_METRICS, 2)) + \
	list(itertools.combinations(CELL_METRICS, 2))

# get 1/2D evaluation statistics
STATS1D = glob_wildcards("code/06-stat_1d-{x}.R").x
STATS2D = glob_wildcards("code/06-stat_2d-{x}.R").x

# get intergation/clustering methods, type b/k refsets & simulators 
METHODS_BATCH = glob_wildcards("code/05-calc_batch-{x}.R").x
METHODS_CLUST = glob_wildcards("code/05-calc_clust-{x}.R").x

# split refsets, methods & simsets by type
REFSETS_TYP_N = [r for r,t in REFSETS.items() if t == "n"]
REFSETS_TYP_B = [r for r,t in REFSETS.items() if t == "b"]
REFSETS_TYP_K = [r for r,t in REFSETS.items() if t == "k"]

METHODS_TYP_N = [m for m,t in METHODS.items() if "n" in t]
METHODS_TYP_B = [m for m,t in METHODS.items() if "b" in t]
METHODS_TYP_K = [m for m,t in METHODS.items() if "k" in t]

METHODS_BY_TYP = {
	"n": METHODS_TYP_N,
	"b": METHODS_TYP_B,
	"k": METHODS_TYP_K}

rts_con = json.load(open("meta/runtimes.json"))
res_rts = list()
res_mbs = list()
for refset,params in rts_con.items():
	reftyp = params["type"]
	methods = METHODS_BY_TYP[reftyp]
	simsets = expand(
		"{refset},{method}",
		refset = refset,
		method = methods)
	# runtimes
	res_rts += expand([
		"outs/rts_{reftyp}-{simset},{ngs},x,{rep}.rds",
		"outs/rts_{reftyp}-{simset},x,{ncs},{rep}.rds"],
		reftyp = reftyp,
		simset = simsets,
		ngs = params["n_genes"],
		ncs = params["n_cells"],
		rep = list(range(1, 6)))
	# memory usage
	res_mbs += [foo.replace("outs", "logs").replace("rds", "txt") for foo in res_rts]

# get target figures
FIGS_QC_REF = glob_wildcards("code/07-plot_qc_ref-{x}.R").x

FIGS_STAT1D = glob_wildcards("code/07-plot_stat_1d-{x}.R").x
FIGS_STAT2D = glob_wildcards("code/07-plot_stat_2d-{x}.R").x

FIGS_STAT1D_STAT1D = glob_wildcards("code/07-plot_stat_1d_by_stat1d-{x}.R").x
FIGS_STAT1D_METHOD = glob_wildcards("code/07-plot_stat_1d_by_method-{x}.R").x
FIGS_STAT1D_REFSET = glob_wildcards("code/07-plot_stat_1d_by_refset-{x}.R").x
FIGS_STAT1D_REFTYP = glob_wildcards("code/07-plot_stat_1d_by_reftyp-{x}.R").x

FIGS_STAT2D_REFTYP = glob_wildcards("code/07-plot_stat_2d_by_reftyp-{x}.R").x

FIGS_BATCH = glob_wildcards("code/07-plot_batch-{x}.R").x
FIGS_CLUST = glob_wildcards("code/07-plot_clust-{x}.R").x

FIGS = glob_wildcards("code/08-fig_{x}.R").x

# ==============================================================================

rule all:
	input:
		"session_info.txt",
		expand([
	# preprocessing
			"data/00-raw/{datset}.rds",
			"data/01-fil/{datset}.rds", 
			"data/02-sub/{refset}.rds",
	# simulation
			"data/03-est/{simset}.rds",
			"data/04-sim/{simset}.rds",
	# dimension reduction
			"outs/dr_ref-{refset}.rds",
			"outs/dr_sim-{simset}.rds",
	# quality control
			"outs/qc_ref-{refset},{metric}.rds",
			"outs/qc_sim-{simset},{metric}.rds"],
			datset = DATSETS,
			refset = REFSETS, 
			simset = SIMSETS, 
			metric = METRICS),
	# evaluation
		expand(
			"outs/stat_1d-{simset},{metric},{stat1d}.rds",
			simset = SIMSETS, 
			metric = METRICS,
			stat1d = STATS1D),
		expand(
			expand(
				"outs/stat_2d-{{simset}},{metric1},{metric2},{{stat2d}}.rds",
				zip,
				metric1 = [m[0] for m in METRIC_PAIRS],
				metric2 = [m[1] for m in METRIC_PAIRS]),
			simset = SIMSETS,
			stat2d = STATS2D),
	# integration
		expand([
			"outs/batch_ref-{refset},{method_batch}.rds",
			"outs/batch_res-{refset},{method_batch}.rds",
			"outs/batch_sim-{refset},{method},{method_batch}.rds",
			"outs/batch_res-{refset},{method},{method_batch}.rds",
			"outs/dr_batch_ref-{refset},{method_batch}.rds",
			"outs/dr_batch_sim-{refset},{method},{method_batch}.rds"],
			refset = REFSETS_TYP_B, 
			method = METHODS_TYP_B,
			method_batch = METHODS_BATCH),
		expand([
			"plts/batch-dimred.{ext}",
			"plts/batch-{fig}_{val}.{ext}"],
			fig = FIGS_BATCH,
			val = ["cms", "ldf", "bcs"],
			ext = ["rds", "pdf"]),
	# clustering
		expand([
			"outs/clust_ref-{refset},{method_clust}.rds",
			"outs/clust_sim-{refset},{method},{method_clust}.rds",
			"outs/clust_res-{refset}.rds"],
			refset = REFSETS_TYP_K, 
			method = METHODS_TYP_K,
			method_clust = METHODS_CLUST),
		expand(
			"plts/clust-{fig}.{ext}",
			fig = FIGS_CLUST,
			ext = ["rds", "pdf"]),
	# outputs
		expand([
			"outs/fns-{pat}.txt",
			"outs/obj-{pat}.rds"],
			pat = [
			"qc_ref", "qc_sim", "stat_1d", "stat_2d", 
			"batch_res", "clust_res", "rts"]),
	# plots
		expand(
			"plts/qc_ref-{fig}.{ext}",
			fig = FIGS_QC_REF,
			ext = ["rds", "pdf"]),
		expand(
			"plts/dimred_{reftyp}.pdf",
			reftyp = ["n", "b", "k"]),
		expand([
			"plts/stat_1d-{fig1d}.{ext}",
			"plts/stat_2d-{fig2d}.{ext}"],
			fig1d = FIGS_STAT1D,
			fig2d = FIGS_STAT2D,
			ext = ["rds", "pdf"]),
		expand([
			"plts/stat_1d_by_stat1d-{fig},{stat1d}.{ext}"],
			fig = FIGS_STAT1D_STAT1D,
			stat1d = STATS1D,
			ext = ["rds", "pdf"]),
		expand([
			"plts/stat_1d_by_reftyp-{fig1d},{reftyp},{stat1d}.{ext}",
			"plts/stat_2d_by_reftyp-{fig2d},{reftyp},{stat2d}.{ext}"], 
			fig1d = FIGS_STAT1D_REFTYP, 
			fig2d = FIGS_STAT2D_REFTYP, 
			reftyp = REFTYPS,
			stat1d = STATS1D,
			stat2d = STATS2D,
			ext = ["rds", "pdf"]),
		# runtimes
		res_rts,
		expand(
			"plts/{plt}_{reftyp}.{ext}",
			reftyp = REFTYPS,
			plt = ["rts", "mbs"],
			ext = ["rds", "pdf"]),
		# figures
		expand("figs/{fig}.pdf", fig = FIGS)

rule session_info:
	priority: 99
	input: 	"code/10-session_info.R"
	output:	"session_info.txt"
	log:	"logs/session_info.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save\
	"--args {output}" {input} {log}'''

# PREPROCESSING ================================================================

# reproducibly retrieve dataset from public source
rule get_data:
	priority: 98
	input: 	"code/00-get_data.R",
			"code/00-get_data-{datset}.R"
	output:	"data/00-raw/{datset}.rds"
	log:	"logs/get_data-{datset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save\
	"--args {input[1]} {output}" {input[0]} {log}'''	

# basic filtering to remove low-quality genes/cells
# & instances (cluster-batch) with few cells
rule fil_data:
	priority: 97
	input: 	"code/01-fil_data.R",
			rules.get_data.output
	output:	"data/01-fil/{datset}.rds"
	log:	"logs/get_data-{datset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save\
	"--args {input[1]} {output}" {input[0]} {log}'''	

# subset datasets into subsets = refsets
# according to .json configuration file
rule sub_data:
	priority: 96
	input: 	"code/02-sub_data.R",
			rules.fil_data.output
	params: "meta/subsets.json"
	output:	"data/02-sub/{datset},{subset}.rds"
	log:	"logs/sub_data-{datset},{subset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	{input[1]} {params} {output}" {input[0]} {log}'''

# SIMULATION ===================================================================

# estimate simulation parameters from refset
# (NULL when estimation & simulation are not separate)
rule est_pars:
	priority: 95
	input: 	"code/03-est_pars.R",
			"code/03-est_pars-{method}.R",
			rules.sub_data.output
	output:	"data/03-est/{datset},{subset},{method}.rds",
	log:	"logs/est_pars-{datset},{subset},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} sub={input[2]} est={output}" {input[0]} {log}'''

# simluate data from parameter estimates or, 
# if unavailable, directly from the subset
rule sim_data:
	priority: 94
	input: 	"code/04-sim_data.R",
			"code/04-sim_data-{method}.R",
			rules.sub_data.output,
			rules.est_pars.output
	output:	"data/04-sim/{datset},{subset},{method}.rds"
	log:	"logs/sim_data-{datset},{subset},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} sub={input[2]} est={input[3]} sim={output}" {input[0]} {log}'''

# DIMENSION REDUCTION ==========================================================

# compute reduced dimensions for each refset
rule dr_ref:
	priority: 93
	input: 	"code/05-calc_dr.R",
			rules.sub_data.output
	output:	"outs/dr_ref-{datset},{subset}.rds"
	log:	"logs/dr_ref-{datset},{subset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	{input[1]} {output}" {input[0]} {log}'''

# compute reduced dimensions for each simset = refset + method
rule dr_sim:
	priority: 93
	input: 	"code/05-calc_dr.R",
			rules.sim_data.output
	output:	"outs/dr_sim-{datset},{subset},{method}.rds"
	log:	"logs/dr_sim-{datset},{subset},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	{input[1]} {output}" {input[0]} {log}'''

# QUALITY CONTROL ==============================================================

# compute QC summaries for each refset
rule qc_ref:
	priority: 93
	input: 	"code/05-calc_qc.R",
			"code/utils-summaries.R",
			"code/05-calc_qc-{metric}.R",
			rules.sub_data.output
	output:	"outs/qc_ref-{datset},{subset},{metric}.rds"
	log:	"logs/qc_ref-{datset},{subset},{metric}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} uts={input[1]}\
	fun={input[2]} sce={input[3]} res={output}" {input[0]} {log}'''

# compute QC summaries for each simset = refset + method
rule qc_sim:
	priority: 93
	input: 	"code/05-calc_qc.R",
			"code/utils-summaries.R",
			"code/05-calc_qc-{metric}.R",
			rules.sim_data.output
	output:	"outs/qc_sim-{datset},{subset},{method},{metric}.rds"
	log:	"logs/qc_sim-{datset},{subset},{method},{metric}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} uts={input[1]}\
	fun={input[2]} sce={input[3]} res={output}" {input[0]} {log}'''

# EVALUATION ===================================================================

# evalute ref. vs. sim. summaries in 1D (univariate)
rule stat_1d:
	priority: 92
	input:	"code/06-stat_1d.R",
			"code/06-stat_1d-{stat1d}.R",
			rules.qc_ref.output,
			rules.qc_sim.output
	output:	"outs/stat_1d-{datset},{subset},{method},{metric},{stat1d}.rds"
	log:	"logs/eval_1d-{datset},{subset},{method},{metric},{stat1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	wcs={wildcards} fun={input[1]} ref={input[2]}\
	sim={input[3]} res={output}" {input[0]} {log}'''

# evalute ref. vs. sim. summary pairs in 2D (bivariate)
rule stat_2d:
	priority: 92
	input:	"code/06-stat_2d.R",
			"code/06-stat_2d-{stat2d}.R",
			x_ref = "outs/qc_ref-{datset},{subset},{metric1}.rds",
			y_ref = "outs/qc_ref-{datset},{subset},{metric2}.rds",
			x_sim = "outs/qc_sim-{datset},{subset},{method},{metric1}.rds",
			y_sim = "outs/qc_sim-{datset},{subset},{method},{metric2}.rds"
	params:	lambda wc, input: ";".join([input.x_ref, input.x_sim]),
			lambda wc, input: ";".join([input.y_ref, input.y_sim])
	output:	"outs/stat_2d-{datset},{subset},{method},{metric1},{metric2},{stat2d}.rds"
	log:	"logs/eval_2d-{datset},{subset},{method},{metric1},{metric2},{stat2d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	wcs={wildcards} fun={input[1]} res={output}\
	x={params[0]} y={params[1]}" {input[0]} {log}'''

# INTEGRATION ==================================================================

# run each intergation method on each refset
rule batch_ref:
	priority: 93	
	input: 	"code/05-calc_batch.R",
			"code/05-calc_batch-{batch_method}.R",
			rules.sub_data.output
	output:	"outs/batch_ref-{datset},{subset},{batch_method}.rds"
	log:	"logs/batch_ref-{datset},{subset},{batch_method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} sce={input[2]} res={output}" {input[0]} {log}'''

# run each intergation method on each simset
rule batch_sim:
	priority: 93	
	input: 	"code/05-calc_batch.R",
			"code/05-calc_batch-{batch_method}.R",
			rules.sim_data.output
	output:	"outs/batch_sim-{datset},{subset},{method},{batch_method}.rds"
	log:	"logs/batch_sim-{datset},{subset},{method},{batch_method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} sce={input[2]} res={output}" {input[0]} {log}'''

# evaluate intergation (via LDF & CMS)
rule eval_batch_ref:
	priority: 92
	input: 	"code/06-eval_batch.R",
			rules.sub_data.output,
			rules.batch_ref.output
	output:	"outs/batch_res-{datset},{subset},{batch_method}.rds"
	log:	"logs/batch_res-{datset},{subset},{batch_method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	{input[1]} {input[2]} {output}" {input[0]} {log}'''

rule eval_batch_sim:
	priority: 92
	input: 	"code/06-eval_batch.R",
			rules.sim_data.output,
			rules.batch_sim.output
	output:	"outs/batch_res-{datset},{subset},{method},{batch_method}.rds"
	log:	"logs/batch_res-{datset},{subset},{method},{batch_method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	{input[1]} {input[2]} {output}" {input[0]} {log}'''

# compute reduced dimensions for each integrated refset
rule dr_batch_ref:
	priority: 91
	input: 	"code/06-dr_batch.R",
			rules.sub_data.output,
			rules.batch_ref.output
	output:	"outs/dr_batch_ref-{datset},{subset},{batch_method}.rds"
	log:	"logs/dr_batch_ref-{datset},{subset},{batch_method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	{input[1]} {input[2]} {output}" {input[0]} {log}'''

# compute reduced dimensions for each integrated simset
rule dr_batch_sim:
	priority: 91
	input: 	"code/06-dr_batch.R",
			rules.sim_data.output,
			rules.batch_sim.output
	output:	"outs/dr_batch_sim-{datset},{subset},{method},{batch_method}.rds"
	log:	"logs/dr_batch_sim-{datset},{subset},{method},{batch_method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	{input[1]} {input[2]} {output}" {input[0]} {log}'''

# CLUSTERING ===================================================================

# run each clustering method on each refset
rule clust_ref:
	priority: 93	
	input: 	"code/05-calc_clust.R",
			"code/05-calc_clust-{clust_method}.R",
			rules.sub_data.output
	output:	"outs/clust_ref-{datset},{subset},{clust_method}.rds"
	log:	"logs/clust_ref-{datset},{subset},{clust_method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} sce={input[2]} res={output}" {input[0]} {log}'''

# run each clustering method on each simset
rule clust_sim:
	priority: 93	
	input: 	"code/05-calc_clust.R",
			"code/05-calc_clust-{clust_method}.R",
			rules.sim_data.output
	output:	"outs/clust_sim-{datset},{subset},{method},{clust_method}.rds"
	log:	"logs/clust_sim-{datset},{subset},{method},{clust_method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} sce={input[2]} res={output}" {input[0]} {log}'''

# evaluate clustering (precision, recall, F1 score 
# using refset assignments as 'ground truth')
rule eval_clust:
	priority: 92
	input: 	"code/06-eval_clust.R",
			"code/utils-clustering.R",
			sce = rules.sub_data.output,
			ref = expand(
				"outs/clust_ref-{{datset}},{{subset}},{clust_method}.rds",
				clust_method = METHODS_CLUST),
			sim = expand(
				"outs/clust_sim-{{datset}},{{subset}},{method},{clust_method}.rds", 
				method = METHODS_TYP_K, 
				clust_method = METHODS_CLUST)
	params: lambda wc, input: ";".join(input.ref),
			lambda wc, input: ";".join(input.sim)
	output:	"outs/clust_res-{datset},{subset}.rds"
	log:	"logs/clust_res-{datset},{subset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} uts={input[1]}\
	sce={input[2]} ref={params[0]} sim={params[1]} res={output}" {input[0]} {log}'''

# RUNTIMES =====================================================================

rule rts:
	priority: 91
	input: 	"code/05-runtimes.R",
			rules.sub_data.output,
			"code/03-est_pars-{method}.R",
			"code/04-sim_data-{method}.R"
	output:	"outs/rts_{reftyp}-{datset},{subset},{method},{ngs},{ncs},{rep}.rds"
	log:	"logs/rts_{reftyp}-{datset},{subset},{method},{ngs},{ncs},{rep}.Rout"
	benchmark: "logs/rts_{reftyp}-{datset},{subset},{method},{ngs},{ncs},{rep}.txt"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input[1]} est={input[2]} sim={input[3]} res={output}" {input[0]} {log}'''

# COLLECTION ===================================================================

# QC summaries
qc_ref = expand(
	"outs/qc_ref-{refset},{metric}.rds",
	refset = REFSETS, metric = METRICS)
qc_sim = expand(
	"outs/qc_sim-{simset},{metric}.rds",
	simset = SIMSETS, metric = METRICS)

# both 1D stats across all simsets & summaries
res_stat1d =  expand(
	"outs/stat_1d-{simset},{metric},{stat1d}.rds", 
	simset = SIMSETS, metric = METRICS, stat1d = STATS1D)

# single 1D stat across all simsets & summaries
def stat1d_by_stat1d(wildcards):
	return expand("outs/stat_1d-{simset},{metric},{stat1d}.rds", 
		simset = SIMSETS, metric = METRICS, stat1d = wildcards.stat1d)

# single 1D stat by method, across all datasets
def stat1d_by_method(wildcards):
	return [x for x in stat1d_by_stat1d(wildcards) if wildcards.method in x]

# single 1D stat by refset, across all methods
def stat1d_by_refset(wildcards):
	return [x for x in stat1d_by_stat1d(wildcards) if wildcards.refset in x]

# single 1D stat by reftype, across all methods
def stat1d_by_reftyp(wildcards):
	return [x for x in stat1d_by_stat1d(wildcards) for s in SIMSETS \
			if SIMSETS.get(s) == wildcards.reftyp and s in x]

# both 2D stats across all simsets & summaries
res_stat2d =  expand(
	expand(
		"outs/stat_2d-{{simset}},{metric1},{metric2},{{stat2d}}.rds", 
		zip,
		metric1 = [m[0] for m in METRIC_PAIRS], 
		metric2 = [m[1] for m in METRIC_PAIRS]),
	simset = SIMSETS, stat2d = STATS2D)

# single 2D stat across all simsets & summaries
def stat2d_by_stat2d(wildcards):
	return expand(
		expand(
			"outs/stat_2d-{{simset}},{metric1},{metric2},{{stat2d}}.rds", 
			zip,
			metric1 = [m[0] for m in METRIC_PAIRS], 
			metric2 = [m[1] for m in METRIC_PAIRS]),
		simset = SIMSETS, 
		stat2d = wildcards.stat2d)

# single 2D stat by method, across all refsets
def stat2d_by_method(wildcards):
	return [x for x in stat2d_by_stat2d(wildcards) if wildcards.method in x]

# single 2D stat by refset, across all methods
def stat2d_by_refset(wildcards):
	return [x for x in stat2d_by_stat2d(wildcards) if wildcards.refset in x]

# single 2D stat by reftype, across all methods
def stat2d_by_reftyp(wildcards):
	return [x for x in stat2d_by_stat2d(wildcards) for s in SIMSETS \
			if SIMSETS.get(s) == wildcards.reftyp and s in x]

# batch correction results
res_batch = expand([
	"outs/batch_res-{refset},{batch_method}.rds",
	"outs/batch_res-{refset},{method},{batch_method}.rds"],
	refset = REFSETS_TYP_B,
	method = METHODS_TYP_B,
	batch_method = METHODS_BATCH)

# clustering results
res_clust = expand(
	"outs/clust_res-{refset}.rds",
	refset = REFSETS_TYP_K)

# dimension reductions
res_dr = expand([
	"outs/dr_ref-{refset}.rds",
	"outs/dr_sim-{refset},{method}.rds",
	"outs/dr_batch_ref-{refset},{batch_method}.rds",
	"outs/dr_batch_sim-{refset},{method},{batch_method}.rds"],
	refset = REFSETS_TYP_B,
	method = METHODS_TYP_B,
	batch_method = METHODS_BATCH)

# runtimes
def rts_by_reftyp(wildcards):
	return [x for x in res_rts if "rts_" + wildcards.reftyp in x]

# memory usage
def mbs_by_reftyp(wildcards):
	return [x for x in res_mbs if "rts_" + wildcards.reftyp in x]

# ------------------------------------------------------------------------------
# write out .rds objects of  
# - quality control summaries
# - 1 & 2D statistics
# - batch correction & clustering results
# ------------------------------------------------------------------------------

data = {
	"qc_ref": qc_ref,
	"qc_sim": qc_sim,
	"stat_1d": res_stat1d,
	"stat_2d": res_stat2d,
	"batch_res": res_batch,
	"clust_res": res_clust,
	"rts": res_rts,
	"mbs": res_mbs}

rule write_fns:
	priority: 90
	input:	"code/09-write_fns.R",
			lambda wildcards: data[wildcards.pat]
	output:	"outs/fns-{pat}.txt"
	log:	"logs/write_fns-{pat}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	wcs={wildcards} txt={output}" {input[0]} {log}'''

rule write_obj:
	priority: 90
	input:	"code/09-write_obj.R",
			"code/utils-plotting.R",
			rules.write_fns.output
	output:	"outs/obj-{pat}.rds"
	log:	"logs/write_obj-{pat}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} txt={input[2]} rds={output}" {input[0]} {log}'''

# PLOTS ========================================================================

rule plot_qc_ref:
	priority: 89
	input:	"code/07-plot_qc_ref-{fig}.R",
			"code/utils-plotting.R",
			"outs/obj-qc_ref.rds"
	output:	expand("plts/qc_ref-{{fig}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_qc_ref-{fig}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} fun={input[1]}\
	res={input[2]} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_rts:
	priority: 89
	input:	"code/07-plot_runtimes.R",
			"code/utils-plotting.R",
			res = rts_by_reftyp
	params:	lambda wc, input: ";".join(input.res)
	output:	expand("plts/rts_{{reftyp}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_rts-{reftyp}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_mbs:
	priority: 89
	input:	"code/07-plot_memory.R",
			"code/utils-plotting.R",
			res = mbs_by_reftyp
	params:	lambda wc, input: ";".join(input.res)
	output:	expand("plts/mbs_{{reftyp}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_mbs-{reftyp}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_dr:
	priority: 89
	input:	"code/07-plot_dimred.R",
			"code/utils-plotting.R",
			ref = expand("outs/dr_ref-{refset}.rds", refset = REFSETS)
	params:	lambda wc, input: ";".join(input.ref)
	output:	"plts/dimred_{reftyp}.pdf"
	log:	"logs/plot_dimred-{reftyp}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} pdf={output}" {input[0]} {log}'''

rule plot_stat1d:
	priority: 89
	input:	"code/07-plot_stat_1d-{fig}.R",
			"code/utils-plotting.R",
			"outs/obj-stat_1d.rds"
	output:	expand("plts/stat_1d-{{fig}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_stat_1d-{fig}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} fun={input[1]}\
	res={input[2]} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_stat_1d_by_stat1d:
	priority: 89
	input:	"code/07-plot_stat_1d_by_stat1d-{fig}.R",
			"code/utils-plotting.R",
			"outs/obj-stat_1d.rds"
	output:	expand("plts/stat_1d_by_stat1d-{{fig}},{{stat1d}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_stat_1d_by_stat1d-{fig},{stat1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={input[2]} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_stat_1d_by_reftyp:
	priority: 89
	input:	"code/07-plot_stat_1d_by_reftyp-{fig}.R",
			"code/utils-plotting.R",
			"outs/obj-stat_1d.rds"
	output:	expand("plts/stat_1d_by_reftyp-{{fig}},{{reftyp}},{{stat1d}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_stat_1d_by_reftyp-{fig},{reftyp},{stat1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} fun={input[1]}\
	res={input[2]} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_stat2d:
	priority: 89
	input:	"code/07-plot_stat_2d-{fig}.R",
			"code/utils-plotting.R",
			"outs/obj-stat_2d.rds"
	output:	expand("plts/stat_2d-{{fig}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_stat_2d-{fig}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} fun={input[1]}\
	res={input[2]} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_stat_2d_by_reftyp:
	priority: 89
	input:	"code/07-plot_stat_2d_by_reftyp-{fig}.R",
			"code/utils-plotting.R",
			res = stat2d_by_reftyp
	params:	lambda wc, input: ";".join(input.res)
	output:	expand("plts/stat_2d_by_reftyp-{{fig}},{{reftyp}},{{stat2d}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_stat_2d_by_reftyp-{fig},{reftyp},{stat2d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_batch:
	priority: 89
	input:	"code/07-plot_batch-{fig}.R",
			"code/utils-plotting.R",
			"code/utils-integration.R",
			res = res_batch
	params:	lambda wc, input: ";".join(input.res)
	output:	expand("plts/batch-{{fig}}_{{val}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_batch-{fig}_{val}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	wcs={wildcards} uts1={input[1]} uts2={input[2]}\
	res={params} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_dr_batch:
	priority: 89
	input:	"code/07-plot_dimred_batch.R",
			"code/utils-plotting.R",
			res = res_dr
	params:	lambda wc, input: ";".join(input.res)
	output:	expand("plts/batch-dimred.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_dr_batch.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} uts={input[1]}\
	res={params} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

rule plot_clust:
	priority: 89
	input:	"code/07-plot_clust-{fig}.R",
			"code/utils-plotting.R",
			res = res_clust
	params:	lambda wc, input: ";".join(input.res)
	output:	expand("plts/clust-{{fig}}.{ext}", ext = ["rds", "pdf"])
	log:	"logs/plot_clust-{fig}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards} uts={input[1]}\
	res={params} rds={output[0]} pdf={output[1]}" {input[0]} {log}'''

# FIGURES ======================================================================

plts = {
	"stat1d": expand(
		"plts/stat_1d_by_reftyp-boxplot,{reftyp},{stat1d}.rds",
		reftyp = REFTYPS, stat1d = STATS1D),
	"stat2d": expand(
		"plts/stat_2d_by_reftyp-boxplot,{reftyp},{stat2d}.rds",
		reftyp = REFTYPS, stat2d = STATS2D),
	"runtimes": expand(
		"plts/rts_{reftyp}.rds",
		reftyp = REFTYPS),
	"memory": expand(
		"plts/mbs_{reftyp}.rds",
		reftyp = REFTYPS),
	"scalability": expand(
		"plts/{which}_{reftyp}.rds",
		which = ["rts", "mbs"],
		reftyp = REFTYPS),
	"scatters": expand(
		"plts/stat_{dim}d-scatters.rds",
		dim = ["1", "2"]),
	"boxplots": expand(
		"plts/stat_1d_by_stat1d-boxplot_by_{by},ks.rds",
		by = ["metric", "method"]),
	"heatmaps": expand([
		"plts/stat_1d_by_reftyp-heatmap,{reftyp},ks.rds", 
		"plts/stat_2d_by_reftyp-heatmap,{reftyp},ks2.rds"], 
		reftyp = REFTYPS),
	"integration": expand(
		"plts/batch-{fig}.rds",
		fig = expand([
			"boxplot_by_method_{val}",
			"boxplot_dX_{val}",
			"heatmap_by_method_{val}",
			"correlations_{val}"],
			val = ["cms", "ldf", "bcs"])),
	"clustering": expand(
		"plts/clust-{fig}.rds",
		fig = ["boxplot_by_method", "boxplot_dF1", "heatmap_by_method", "correlations"]),
	"mds": expand(
		"plts/stat_1d_by_reftyp-mds,{reftyp},ks.rds",
		reftyp = REFTYPS),
	"summaries": [
		"plts/qc_ref-correlations.rds",
		"plts/stat_1d_by_stat1d-correlations,ks.rds",
        "plts/stat_1d_by_stat1d-mds,ks.rds",
        "plts/stat_1d_by_stat1d-pca,ks.rds"]
}

rule figs:
	priority: 1
	input:	"code/08-fig_{fig}.R",
			"code/utils-plotting.R",
			rds = lambda wildcards: plts[wildcards.fig]
	params: lambda wc, input: ";".join(input.rds)
	output:	"figs/{fig}.pdf"
	log:	"logs/fig_{fig}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	uts={input[1]} rds={params} pdf={output}" {input[0]} {log}'''