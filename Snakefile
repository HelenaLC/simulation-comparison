import re
import json
import itertools

configfile: "config.yaml"
R = config["R"]

METHODS = json.loads(open("config/methods.json").read())
# METRICS = json.loads(open("config/metrics.json").read())

G_METRICS = glob_wildcards("code/05-gene_qc-{m}.R").m
C_METRICS = glob_wildcards("code/05-cell_qc-{m}.R").m
METRICS = G_METRICS + C_METRICS
TYPE_METRIC = ["gene"] * len(G_METRICS) + ["cell"] * len(C_METRICS)

ex = ["cor", "sil", "pve"]

gene_metrics_pairs = list(itertools.combinations([x for x in G_METRICS if x not in ex], 2))
cell_metrics_pairs = list(itertools.combinations([x for x in C_METRICS if x not in ex], 2))

DATSETS = glob_wildcards("code/00-get_data-{d}.R").d
SUBSETS = json.loads(open("config/subsets.json").read())

REFSETS = {"{}.{}".format(d,s): t \
	for d in SUBSETS.keys() \
	for s in SUBSETS[d].keys() \
	for t in SUBSETS[d][s]["type"]}

SUBSETS = {
	"dat": [d for d in SUBSETS.keys() for s in SUBSETS[d].keys()],
	"sub": [s for d in SUBSETS.keys() for s in SUBSETS[d].keys()]}

RUNS = {
	"ref":[r for r in REFSETS.keys() for m in METHODS.keys() if REFSETS[r] in METHODS[m]], 
	"mid":[m for r in REFSETS.keys() for m in METHODS.keys() if REFSETS[r] in METHODS[m]]}

# ------------------------------------------------------------------------------

qc_ref_dirs = expand(
	expand("results/qc_ref-{{refset}},{type}_{metric}.rds",
		zip, type = TYPE_METRIC, metric= METRICS), 
	refset = REFSETS)

qc_sim_dirs = expand(
	expand("results/qc_sim-{refset},{{type}}_{{metric}},{method}.rds",
		zip, refset = RUNS["ref"], method = RUNS["mid"]),
	zip , type = TYPE_METRIC, metric= METRICS)

dr_ref_dirs = expand("results/dr_ref-{refset}.rds", refset = REFSETS)
dr_sim_dirs = expand("results/dr_sim-{refset},{method}.rds", zip, refset = RUNS["ref"], method = RUNS["mid"])

# one-/two-dimensional tests
stats_1d = glob_wildcards("code/06-stat_1d-{x}.R").x
stats_2d = glob_wildcards("code/06-stat_2d-{x}.R").x

stats_1d_dirs = \
expand(
	expand("results/stat_1d,{stat_1d}-{refset},{{type}}_{{metric}}.rds", 
		stat_1d = stats_1d, refset= REFSETS),
	zip, type = TYPE_METRIC, metric= METRICS)

stats_2d_dirs = \
expand(
	expand("results/stat_2d,{{stat_2d}}-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.rds", zip,
		metric1 = [m[0] for m in gene_metrics_pairs],
		metric2 = [m[1] for m in gene_metrics_pairs]),
	stat_2d = stats_2d,
	type = ['gene'],
	refset = REFSETS) + \
expand(
	expand("results/stat_2d,{{stat_2d}}-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.rds", zip,
		metric1 = [m[0] for m in cell_metrics_pairs],
		metric2 = [m[1] for m in cell_metrics_pairs]),
	stat_2d = stats_2d,
	type = ['cell'],
	refset = REFSETS)

plots_1d = glob_wildcards("code/07-plot_1d-{x}.R").x
plots_2d = glob_wildcards("code/07-plot_2d-{x}.R").x

rule all:
	input:
		"session_info.txt",
# preprocessing
		expand("data/00-raw/{datset}.rds", datset = DATSETS),
		expand("data/01-fil/{datset}.rds", datset = DATSETS),
		expand(
			"data/02-sub/{datset}.{subset}.rds", zip,
			datset = SUBSETS["dat"], subset = SUBSETS["sub"]),
# simulation
		expand(
			"data/03-est/{refset},{method}.rds", zip,
			refset = RUNS["ref"], method = RUNS["mid"]),
		expand(
			"data/04-sim/{refset},{method}.rds", zip,
			refset = RUNS["ref"], method = RUNS["mid"]),
# quality control
		qc_ref_dirs, qc_sim_dirs,
		dr_ref_dirs, dr_sim_dirs,
# evaluation
		stats_1d_dirs, stats_2d_dirs,
		expand("results/comb_1d-{stat_1d}.rds", stat_1d = stats_1d),
		expand("results/comb_2d-{stat_2d}.rds", stat_2d = stats_2d),
# visualization
		expand(
			expand(
				"plots/qc_{{refset}},{type}_{metric}.pdf",
				zip, type = TYPE_METRIC, metric = METRICS
			), refset = REFSETS),
		expand(
			expand(
				"plots/qc_2d-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.pdf", zip, 
				metric1 = [m[0] for m in gene_metrics_pairs],
				metric2 = [m[1] for m in gene_metrics_pairs]),
			type = "gene", refset = REFSETS),
		expand(
			expand(
				"plots/qc_2d-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.pdf", zip,
				metric1 = [m[0] for m in cell_metrics_pairs],
				metric2 = [m[1] for m in cell_metrics_pairs]), 
			type = "cell", refset = REFSETS),
		expand("plots/dr-{refset}.pdf", refset = REFSETS),
		expand("plots/stat_1d-{plot_1d},{stat_1d}.pdf", plot_1d = plots_1d, stat_1d = stats_1d),
		expand("plots/stat_2d-{plot_2d},{stat_2d}.pdf", plot_2d = plots_2d, stat_2d = stats_2d)

# PREPROCESSING ================================================================

rule get_data:
	input:	"code/00-get_data-{datset}.R"
	output:	"data/00-raw/{datset}.rds"
	log:	"logs/00-get_data-{datset}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	{output}" {input} {log}'''

rule fil_data:
	input:	"code/01-fil_data.R",
			raw = rules.get_data.output
	output:	"data/01-fil/{datset}.rds"
	log:	"logs/01-fil_data-{datset}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	raw={input.raw} fil={output}" {input[0]} {log}'''

rule sub_data:
	input:	"code/02-sub_data.R",
			fil = rules.fil_data.output
	params:	con = "config/subsets.json"
	output:	"data/02-sub/{datset}.{subset}.rds"
	log:	"logs/02-sub_data-{datset}.{subset}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fil={input.fil} con={params.con} sub={output}" {input[0]} {log}'''

# SIMULATION ===================================================================

rule est_pars:
	priority: -4
	input:	"code/03-est_pars.R",
			sce = "data/02-sub/{refset}.rds",
			fun = "code/03-est_pars-{method}.R"
	output:	"data/03-est/{refset},{method}.rds"
	log:	"logs/03-est_pars-{refset},{method}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input.sce} fun={input.fun} est={output}" {input[0]} {log}'''

rule sim_data:
	priority: -5
	input:	"code/04-sim_data.R",
			est = rules.est_pars.output,
			sub = "data/02-sub/{refset}.rds",
			fun = "code/04-sim_data-{method}.R"
	output:	"data/04-sim/{refset},{method}.rds"
	log:	"logs/04-sim_data-{refset},{method}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	est={input.est} sub={input.sub}\
	fun={input.fun} sim={output}" {input[0]} {log}'''

# QUALITY CONTROL ==============================================================

rule qc_ref:
	priority: 1
	input: "code/05-calc_qc.R",
			sce = "data/02-sub/{refset}.rds",
			fun = "code/05-{type}_qc-{metric}.R"
	output: "results/qc_ref-{refset},{type}_{metric}.rds"
	log: "logs/05-qc_ref-{refset},{type}_{metric}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input.sce} fun={input.fun} res={output}" {input[0]} {log}'''

rule qc_sim:
	input: "code/05-calc_qc.R",
			sce = rules.sim_data.output,
			fun = "code/05-{type}_qc-{metric}.R"
	output: "results/qc_sim-{refset},{type}_{metric},{method}.rds"
	log: "logs/05-qc_sim-{refset},{type}_{metric},{method}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input.sce} fun={input.fun} res={output}" {input[0]} {log}'''

# DIMENSIONALITY REDUCTION =====================================================

rule dr_ref:
	input: 	"code/05-calc_dr.R",
			"data/02-sub/{refset}.rds"
	output:	"results/dr_ref-{refset}.rds"
	log:	"logs/05-dr_ref-{refset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	sce={input[1]} res={output}" {input[0]} {log}'''

rule dr_sim:
	input: 	"code/05-calc_dr.R",
			rules.sim_data.output
	output:	"results/dr_sim-{refset},{method}.rds"
	log:	"logs/05-dr_sim-{refset},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	sce={input[1]} res={output}" {input[0]} {log}'''

# EVALUATION ===================================================================

# one-dimensional test for each gene & cell metric
rule eval_1d:
	input: "code/06-eval_1d.R",
			fun = "code/06-stat_1d-{stat_1d}.R",
			ref = rules.qc_ref.output,
			sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset, wc.type, wc.metric) in x]
	params: lambda wc, input: ";".join(input.sim)
	output: "results/stat_1d,{stat_1d}-{refset},{type}_{metric}.rds"
	log: "logs/06-eval_1d,{stat_1d}-{refset},{type}_{metric}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input.fun} ref={input.ref} sim={params} res={output}" {input[0]} {log}'''

# two-dimensional test for each pair of gene / cell metrics
rule eval_2d:
	input:	"code/06-eval_2d.R",
			fun = "code/06-stat_2d-{stat_2d}.R",
			x_ref = "results/qc_ref-{refset},{type}_{metric1}.rds",
			y_ref = "results/qc_ref-{refset},{type}_{metric2}.rds",
			x_sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset,wc.type, wc.metric1) in x],
			y_sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset,wc.type, wc.metric2) in x]
	params: x_sim = lambda wc, input: ";".join(input.x_sim),
			y_sim = lambda wc, input: ";".join(input.y_sim)
	output:	"results/stat_2d,{stat_2d}-{refset},{type}_{metric1},{type}_{metric2}.rds"
	log:	"logs/06-eval_2d,{stat_2d}-{refset},{type}_{metric1},{type}_{metric2}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	x_ref={input.x_ref} y_ref={input.y_ref}\
	x_sim={params.x_sim} y_sim={params.y_sim}\
	fun={input.fun} res={output}" {input[0]} {log}'''

# for each statistic, combine results across datasets & methods
rule comb_1d:
	input:	"code/06-comb_1d.R",
			res = lambda wc: [x for x in stats_1d_dirs \
				if "stat_1d,{}-".format(wc.stat_1d) in x]
	params:	lambda wc, input: ";".join(input.res)
	output:	"results/comb_1d-{stat_1d}.rds"
	log:	"logs/06-comb_1d-{stat_1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	{params} {output}" {input[0]} {log}'''

rule comb_2d:
	input:	"code/06-comb_2d.R",
			res = lambda wc: [x for x in stats_2d_dirs \
				if "stat_2d,{}-".format(wc.stat_2d) in x]
	params:	lambda wc, input: ";".join(input.res)
	output:	"results/comb_2d-{stat_2d}.rds"
	log:	"logs/06-comb_2d-{stat_2d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	{params} {output}" {input[0]} {log}'''

# VISUALIZATION ================================================================

rule plot_qc_1d:
	input: "code/07-plot_qc.R",
	 		ref = rules.qc_ref.output, \
	  		sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset,wc.type,wc.metric) in x]
	params: lambda wc, input: ";".join(input.sim)
	output: "plots/qc_{refset},{type}_{metric}.pdf"
	log: "logs/07-plot_qc-{refset},{type}_{metric}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	ref={input.ref} sim={params} fig={output}" {input[0]} {log}'''

rule plot_qc_2d:
	input: "code/07-plot_qc_2d-by_refset.R",
			x_ref = "results/qc_ref-{refset},{type}_{metric1}.rds",
			y_ref = "results/qc_ref-{refset},{type}_{metric2}.rds",
			x_sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset, wc.type, wc.metric1) in x],
			y_sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset, wc.type, wc.metric2) in x]
	params: x_sim = lambda wc, input: ";".join(input.x_sim),
			y_sim = lambda wc, input: ";".join(input.y_sim)
	output: "plots/qc_2d-{refset},{type}_{metric1},{type}_{metric2}.pdf"
	log: "logs/07-plot_qc_2d-{refset},{type}_{metric1},{type}_{metric2}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	x_ref={input.x_ref} y_ref={input.y_ref}\
	x_sim={params.x_sim} y_sim={params.y_sim}\
	fig={output}" {input[0]} {log}'''

rule plot_dr:
	input:	"code/07-plot_dr.R",
			ref = rules.dr_ref.output,
			sim = lambda wc: [x for x in dr_sim_dirs if wc.refset in x]
	params:	lambda wc, input: ";".join(input.sim)
	output:	"plots/dr-{refset}.pdf"
	log:	"logs/07-plot_dr-{refset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	ref={input.ref} sim={params} fig={output}" {input[0]} {log}'''

rule plot_1d:
	input:	"code/07-plot_1d-{plot_1d}.R",
			res = rules.comb_1d.output
	params: lambda wc, input: ";".join(input.res)
	output:	"plots/stat_1d-{plot_1d},{stat_1d}.pdf"
	log:	"logs/07-plot_1d-{plot_1d},{stat_1d}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	res={params} fig={output}" {input[0]} {log}'''

rule plot_2d:
	input:	"code/07-plot_2d-{plot_2d}.R",
			res = rules.comb_2d.output
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/stat_2d-{plot_2d},{stat_2d}.pdf"
	log: 	"logs/07-plot_2d-{plot_2d},{stat_2d}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	res={params} fig={output}" {input[0]} {log}'''

# SESSION INFO =================================================================

rule session_info:
	input:	"code/10-session_info.R"
	output:	"session_info.txt"
	log:	"logs/10-session_info.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save\
	"--args {output}" {input[0]} {log}'''