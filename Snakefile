import json
import itertools

configfile: "config.yaml"
R = config["R"]

DATSETS = glob_wildcards("scripts/00-get_data-{x}.R").x
SUBSETS = json.loads(open("config/subsets.json").read())
METHODS = json.loads(open("config/methods.json").read())

METHODS = {m:t for m,t in METHODS.items() if m in glob_wildcards("scripts/03-est_pars-{x}.R").x}

# combine DATSETS & SUBSETS into single REFSETS
# storing its 'type' (one of 'n', 'b', 'k')
REFSETS = {"{},{}".format(d,s): t \
	for d in SUBSETS.keys() \
	for s in SUBSETS[d].keys() \
	for t in SUBSETS[d][s]["type"]}
REFTYPS = set(REFSETS.values())

# combine REFSETS & METHODS into SIMSETS 
# if the method supports the refset's 'type'
SIMSETS = ["{},{}".format(r,m) \
	for r in REFSETS.keys() \
	for m in METHODS.keys() \
	if REFSETS[r] in METHODS[m]]

METRICS = glob_wildcards("scripts/05-calc_qc-{x}.R").x
GENE_METRICS = [m for m in METRICS if "gene_" in m]
CELL_METRICS = [m for m in METRICS if "cell_" in m]

ex = ["gene_cor", "cell_cor", "gene_pve", "cell_sw"]
METRIC_PAIRS = \
	list(itertools.combinations([m for m in GENE_METRICS if m not in ex], 2)) + \
	list(itertools.combinations([m for m in CELL_METRICS if m not in ex], 2))

STATS1D = glob_wildcards("scripts/06-stat_1d-{x}.R").x
STATS2D = glob_wildcards("scripts/06-stat_2d-{x}.R").x

STAT1D_PLTS = glob_wildcards("scripts/07-plot_stat_1d-{x}.R").x
STAT1D_REFTYP_PLTS = glob_wildcards("scripts/07-plot_stat_1d_by_reftyp-{x}.R").x
STAT1D_METHOD_PLTS = glob_wildcards("scripts/07-plot_stat_1d_by_method-{x}.R").x

rule all:
	input:
		"session_info.txt",
# preprocessing
		expand("data/00-raw/{datset}.rds", datset = DATSETS),
		expand("data/01-fil/{datset}.rds", datset = DATSETS),
		expand("data/02-sub/{refset}.rds", refset = REFSETS),
# simulation
		expand("data/03-est/{simset}.rds", simset = SIMSETS),
		expand("data/04-sim/{simset}.rds", simset = SIMSETS),
# quality control
		expand("results/qc_ref-{refset},{metric}.rds", refset = REFSETS, metric = METRICS),
		expand("results/qc_sim-{simset},{metric}.rds", simset = SIMSETS, metric = METRICS),
# evaluation
		expand("results/dr_ref-{refset}.rds", refset = REFSETS),
		expand("results/dr_sim-{simset}.rds", simset = SIMSETS),
		expand("results/stat_qc-{refset},{metric}.rds",
			refset = REFSETS, metric = METRICS),
		expand("results/stat_1d-{simset},{metric},{stat1d}.rds",
			simset = SIMSETS, metric = METRICS, stat1d = STATS1D),
		expand(expand("results/stat_2d-{{simset}},{metric1},{metric2},{{stat2d}}.rds",
			zip,
			metric1 = [m[0] for m in METRIC_PAIRS],
			metric2 = [m[1] for m in METRIC_PAIRS]),
			simset = SIMSETS, stat2d = STATS2D),
# visualization
		expand("plots/dr-{refset}.{ext}", refset = REFSETS, ext = ["pdf", "rds"]),
		expand("plots/qc_1d-{refset}.{ext}", refset = REFSETS, ext = ["pdf", "rds"]),
		expand("plots/qc_2d-{refset}.pdf", refset = REFSETS),
		expand("plots/stat_1d-{plt},{stat1d}.{ext}", plt = STAT1D_PLTS, stat1d = STATS1D, ext = ["pdf", "rds"]),
		expand("plots/stat_1d_by_refset-{refset},{stat1d}.{ext}", refset = REFSETS, stat1d = STATS1D, ext = ["pdf", "rds"]),
		expand("plots/stat_1d_by_reftyp-{plt},{reftyp},{stat1d}.{ext}", 
			plt = STAT1D_REFTYP_PLTS, reftyp = REFTYPS, stat1d = STATS1D, ext = ["pdf", "rds"]),
		expand("plots/stat_1d_by_method-{plt},{method},{stat1d}.{ext}", 
			plt = STAT1D_METHOD_PLTS, method = METHODS, stat1d = STATS1D, ext = ["pdf", "rds"]),
		expand("plots/stat_2d_by_refset-{refset},{stat2d}.{ext}", refset = REFSETS, stat2d = STATS2D, ext = ["pdf", "rds"]),
		expand("plots/stat_2d_by_reftyp-{reftyp},{stat2d}.{ext}", reftyp = REFTYPS, stat2d = STATS2D, ext = ["pdf", "rds"])

# PREPROCESSING ================================================================

rule get_data:
	priority: 98
	input: 	"scripts/00-get_data-{datset}.R"
	output:	"data/00-raw/{datset}.rds"
	log:	"logs/get_data-{datset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save\
	"--args {output}" {input} {log}'''	

rule fil_data:
	priority: 97
	input: 	"scripts/01-fil_data.R",
			rules.get_data.output
	output:	"data/01-fil/{datset}.rds"
	log:	"logs/fil_data-{datset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save\
	"--args {input[1]} {output}" {input[0]} {log}'''	

rule sub_data:
	priority: 96
	input: 	"scripts/02-sub_data.R",
			rules.fil_data.output
	params: "config/subsets.json"
	output:	"data/02-sub/{datset},{subset}.rds"
	log:	"logs/sub_data-{datset},{subset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	{input[1]} {params} {output}" {input[0]} {log}'''

# SIMULATION ===================================================================

rule est_pars:
	priority: 95
	input: 	"scripts/03-est_pars.R",
			"scripts/03-est_pars-{method}.R",
			rules.sub_data.output
	output:	"data/03-est/{datset},{subset},{method}.rds"
	log:	"logs/est_pars-{datset},{subset},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args fun={input[1]}\
	sub={input[2]} est={output}" {input[0]} {log}'''

rule sim_data:
	priority: 94
	input: 	"scripts/04-sim_data.R",
			"scripts/04-sim_data-{method}.R",
			rules.sub_data.output,
			rules.est_pars.output
	output:	"data/04-sim/{datset},{subset},{method}.rds"
	log:	"logs/sim_data-{datset},{subset},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args fun={input[1]}\
	sub={input[2]} est={input[3]} sim={output}" {input[0]} {log}'''

# QUALITY CONTROL ==============================================================

rule qc_ref:
	priority: 93
	input: 	"scripts/05-calc_qc.R",
			"scripts/05-calc_qc-{metric}.R",
			rules.sub_data.output
	output:	"results/qc_ref-{datset},{subset},{metric}.rds"
	log:	"logs/qc_ref-{datset},{subset},{metric}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} sce={input[2]} res={output}" {input[0]} {log}'''

rule qc_sim:
	priority: 93
	input: 	"scripts/05-calc_qc.R",
			"scripts/05-calc_qc-{metric}.R",
			rules.sim_data.output
	output:	"results/qc_sim-{datset},{subset},{method},{metric}.rds"
	log:	"logs/qc_sim-{datset},{subset},{method},{metric}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} sce={input[2]} res={output}" {input[0]} {log}'''

# DIMENSIONALITY REDUCTION =====================================================

rule dr_ref:
	priority: 92
	input: 	"scripts/05-calc_dr.R",
			rules.sub_data.output
	output:	"results/dr_ref-{datset},{subset}.rds"
	log:	"logs/dr_ref-{datset},{subset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input[1]} res={output}" {input[0]} {log}'''

rule dr_sim:
	priority: 92	
	input: 	"scripts/05-calc_dr.R",
			rules.sim_data.output
	output:	"results/dr_sim-{datset},{subset},{method}.rds"
	log:	"logs/dr_sim-{datset},{subset},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input[1]} res={output}" {input[0]} {log}'''

# EVALUATION ===================================================================

rule eval_qc:
	priority: 91
	input:	"scripts/06-eval_qc.R",
			rules.qc_ref.output
	output:	"results/stat_qc-{datset},{subset},{metric}.rds"
	log:	"logs/eval_qc-{datset},{subset},{metric}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args 
	wcs={wildcards} dat={input[1]} res={output}" {input[0]} {log}'''

rule eval_1d:
	priority: 90
	input:	"scripts/06-eval_1d.R",
			"scripts/06-stat_1d-{stat1d}.R",
			rules.qc_ref.output,
			rules.qc_sim.output
	output:	"results/stat_1d-{datset},{subset},{method},{metric},{stat1d}.rds"
	log:	"logs/eval_1d-{datset},{subset},{method},{metric},{stat1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	wcs={wildcards} fun={input[1]} ref={input[2]}\
	sim={input[3]} res={output}" {input[0]} {log}'''

rule eval_2d:
	priority: 90
	input:	"scripts/06-eval_2d.R",
			"scripts/06-stat_2d-{stat2d}.R",
			x_ref = "results/qc_ref-{datset},{subset},{metric1}.rds",
			y_ref = "results/qc_ref-{datset},{subset},{metric2}.rds",
			x_sim = "results/qc_sim-{datset},{subset},{method},{metric1}.rds",
			y_sim = "results/qc_sim-{datset},{subset},{method},{metric2}.rds"
	params:	lambda wc, input: ";".join([input.x_ref, input.x_sim]),
			lambda wc, input: ";".join([input.y_ref, input.y_sim])
	output:	"results/stat_2d-{datset},{subset},{method},{metric1},{metric2},{stat2d}.rds"
	log:	"logs/eval_2d-{datset},{subset},{method},{metric1},{metric2},{stat2d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	wcs={wildcards} fun={input[1]} res={output}\
	x={params[0]} y={params[1]}" {input[0]} {log}'''

# COLLECTION ===================================================================

def dr_by_refset(wildcards):
	ref = expand("results/dr_ref-{refset}.rds", refset = wildcards.refset)
	sim = expand("results/dr_sim-{simset}.rds", simset = [s for s in SIMSETS if wildcards.refset in s])
	return ref + sim

def qc_by_refset(wildcards):
	ref = expand("results/qc_ref-{refset},{metric}.rds", refset = wildcards.refset, metric = METRICS)
	sim = expand("results/qc_sim-{simset},{metric}.rds", simset = [s for s in SIMSETS if wildcards.refset in s], metric = METRICS)
	return ref + sim

def stat1d(wildcards):
	return expand("results/stat_1d-{simset},{metric},{stat1d}.rds", 
		simset = SIMSETS, metric = METRICS, stat1d = wildcards.stat1d)

def stat1d_by_method(wildcards):
	return [x for x in stat1d(wildcards) if wildcards.method in x]

def stat1d_by_refset(wildcards):
	return [x for x in stat1d(wildcards) if wildcards.refset in x]

def stat1d_by_reftyp(wildcards):
	return [x for x in stat1d(wildcards) for r in REFSETS \
			if REFSETS.get(r) == wildcards.reftyp and r in x]

def stat2d(wildcards):
	return expand(expand("results/stat_2d-{{simset}},{metric1},{metric2},{{stat2d}}.rds", 
		zip,
		metric1 = [m[0] for m in METRIC_PAIRS], 
		metric2 = [m[1] for m in METRIC_PAIRS]),
		simset = SIMSETS, 
		stat2d = wildcards.stat2d)

def stat2d_by_method(wildcards):
	return [x for x in stat2d(wildcards) if wildcards.method in x]

def stat2d_by_refset(wildcards):
	return [x for x in stat2d(wildcards) if wildcards.refset in x]

def stat2d_by_reftyp(wildcards):
	return [x for x in stat2d(wildcards) for r in REFSETS \
			if REFSETS.get(r) == wildcards.reftyp and r in x]

# VISUALIZATION ================================================================

rule plot_dr:
	priority: 89
	input:	"scripts/07-plot_dr.R",
			"scripts/utils-plotting.R",
			res = dr_by_refset
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/dr-{refset}.pdf",
			"plots/dr-{refset}.rds"
	log:	"logs/plot_dr-{refset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} plt={output[0]} ggp={output[1]}" {input[0]} {log}'''

rule plot_qc_1d:
	priority: 89
	input:	"scripts/07-plot_qc_1d.R",
			"scripts/utils-plotting.R",
			res = qc_by_refset
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/qc_1d-{refset}.pdf",
			"plots/qc_1d-{refset}.rds"
	log:	"logs/plot_qc_1d-{refset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} plt={output[0]} ggp={output[1]}" {input[0]} {log}'''

rule plot_qc_2d:
	priority: 89
	input:	"scripts/07-plot_qc_2d.R",
			"scripts/utils-plotting.R",
			res = qc_by_refset
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/qc_2d-{refset}.pdf"
	log:	"logs/plot_qc_2d-{refset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} fig={output}" {input[0]} {log}'''

rule plot_stat_1d:
	priority: 89
	input:	"scripts/07-plot_stat_1d-{plt}.R",
			"scripts/utils-plotting.R",
			res = stat1d
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/stat_1d-{plt},{stat1d}.pdf",
			"plots/stat_1d-{plt},{stat1d}.rds"
	log:	"logs/plot_stat_1d-{plt},{stat1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} plt={output[0]} ggp={output[1]}" {input[0]} {log}'''

rule plot_stat_1d_by_refset:
	priority: 89
	input:	"scripts/07-plot_stat_1d_by_refset.R",
			"scripts/utils-plotting.R",
			res = stat1d_by_refset
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/stat_1d_by_refset-{refset},{stat1d}.pdf",
			"plots/stat_1d_by_refset-{refset},{stat1d}.rds"
	log:	"logs/plot_stat_1d_by_refset-{refset},{stat1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} plt={output[0]} ggp={output[1]}" {input[0]} {log}'''

rule plot_stat_1d_by_reftyp:
	priority: 89
	input:	"scripts/07-plot_stat_1d_by_reftyp-{plt}.R",
			"scripts/utils-plotting.R",
			res = stat1d_by_reftyp
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/stat_1d_by_reftyp-{plt},{reftyp},{stat1d}.pdf",
			"plots/stat_1d_by_reftyp-{plt},{reftyp},{stat1d}.rds"
	log:	"logs/plot_stat_1d_by_reftyp-{plt},{reftyp},{stat1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} plt={output[0]} ggp={output[1]}" {input[0]} {log}'''

rule plot_stat_1d_by_method:
	priority: 89
	input:	"scripts/07-plot_stat_1d_by_method-{plt}.R",
			"scripts/utils-plotting.R",
			res = stat1d_by_method
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/stat_1d_by_method-{plt},{method},{stat1d}.pdf",
			"plots/stat_1d_by_method-{plt},{method},{stat1d}.rds"
	log:	"logs/plot_stat_1d_by_method-{plt},{method},{stat1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} plt={output[0]} ggp={output[1]}" {input[0]} {log}'''

rule plot_stat_2d_by_refset:
	priority: 89
	input:	"scripts/07-plot_stat_2d_by_refset.R",
			"scripts/utils-plotting.R",
			res = stat2d_by_refset
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/stat_2d_by_refset-{refset},{stat2d}.pdf",
			"plots/stat_2d_by_refset-{refset},{stat2d}.rds"
	log:	"logs/plot_stat_2d_by_refset-{refset},{stat2d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} plt={output[0]} ggp={output[1]}" {input[0]} {log}'''

rule plot_stat_2d_by_reftyp:
	priority: 89
	input:	"scripts/07-plot_stat_2d_by_reftyp.R",
			"scripts/utils-plotting.R",
			res = stat2d_by_reftyp
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/stat_2d_by_reftyp-{reftyp},{stat2d}.pdf",
			"plots/stat_2d_by_reftyp-{reftyp},{stat2d}.rds"
	log:	"logs/plot_stat_2d_by_reftyp-{reftyp},{stat2d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input[1]} res={params} plt={output[0]} ggp={output[1]}" {input[0]} {log}'''

# ==============================================================================

rule session_info:
	priority: 99
	input: 	"scripts/10-session_info.R"
	output:	"session_info.txt"
	log:	"logs/session_info.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save\
	"--args {output}" {input} {log}'''