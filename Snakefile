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

gene_metrics_combi = list(itertools.combinations(G_METRICS, 2))
cell_metrics_combi = list(itertools.combinations(C_METRICS, 2))

# gene_metrics = list(itertools.combinations([m for m in METRICS if "gene_" in m], 2))
# cell_metrics = list(itertools.combinations([m for m in METRICS if "cell_" in m], 2))

DATSETS = glob_wildcards("code/00-get_data-{d}.R").d
SUBSETS = json.loads(open("config/subsets.json").read())

REFSETS = {"{},{}".format(d,s): t \
	for d in SUBSETS.keys() \
	for s in SUBSETS[d].keys() \
	for t in SUBSETS[d][s]["type"]}

SUBSETS = {
	"dat": [d for d in SUBSETS.keys() for s in SUBSETS[d].keys()],
	"sub": [s for d in SUBSETS.keys() for s in SUBSETS[d].keys()]}

RUNS = {
	"ref":[r for r in REFSETS.keys() for m in METHODS.keys() if REFSETS[r] in METHODS[m]], 
	"mid":[m for r in REFSETS.keys() for m in METHODS.keys() if REFSETS[r] in METHODS[m]]}

# qc_dirs = expand(expand("results/qc-{refset},{{metric}},{method}.rds", zip,
# 	refset = RUNS["ref"], method = RUNS["mid"]), metric = METRICS)
#ks_dirs = expand("results/ks-{refset},{metric}.rds", refset = REFSETS, metric = METRICS)


ks_dirs = expand(
			expand("results/ks-{refset},{{type}}_{{metric}}.rds",refset= REFSETS),
			zip, type = TYPE_METRIC,metric= METRICS)
qc_sim_dirs= expand(
				expand("results/qc_sim-{refset},{{type}}_{{metric}},{method}.rds",
				zip, refset=RUNS["ref"],method=RUNS["mid"]
			), zip , type = TYPE_METRIC,metric= METRICS)

rule all:
	input:
		expand("data/00-raw/{datset}.rds", datset = DATSETS),
		expand("data/01-fil/{datset}.rds", datset = DATSETS),
		expand(
			"data/02-sub/{datset},{subset}.rds", zip,
			datset = SUBSETS["dat"], subset = SUBSETS["sub"]),
		expand(
			"data/03-est/{refset},{method}.rds", zip,
			refset = RUNS["ref"], method = RUNS["mid"]),
		expand(
			"data/04-sim/{refset},{method}.rds", zip,
			refset = RUNS["ref"], method = RUNS["mid"]),
		# expand(
		# 	"results/qc-{refset},{metric}.rds",
		# 	refset = REFSETS, metric = METRICS),
		expand(
			expand("results/qc_ref-{{refset}},{type}_{metric}.rds",
				zip,type = TYPE_METRIC,metric= METRICS
			), refset = REFSETS),
		qc_sim_dirs,
		expand(
			expand("plots/qc_{{refset}},{type}_{metric}.pdf",
				zip,type=TYPE_METRIC,metric=METRICS
				), refset = REFSETS),
		ks_dirs,
		expand("plots/ks_summary_{refset}.pdf", refset=REFSETS),
		expand("plots/ks.pdf"),

		expand(
			expand("results/{{comp_metric}}-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.rds", zip,
				metric1 = [m[0] for m in gene_metrics_combi],
				metric2 = [m[1] for m in gene_metrics_combi],
			),comp_metric = ["emd"],
			type = ['gene'],
			refset = REFSETS),
		expand(
			expand("results/{{comp_metric}}-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.rds", zip,
				metric1=[m[0] for m in cell_metrics_combi],
				metric2=[m[1] for m in cell_metrics_combi],
			),comp_metric = ["emd"],
			type=['cell'],
			refset=REFSETS
		)

		# expand(
		# 	expand("results/{{comp_metric}}-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.rds", zip,
		# 		metric1 = [m[0] for m in cell_metrics_combi],
		# 		metric2 = [m[1] for m in cell_metrics_combi]
		# 	), comp_metric = [ "emd"],
		# 	type = ['cell'],
		# 	refset = REFSETS),



		# expand(
		# 	expand("plots/dy-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.pdf", zip,
		# 		metric1 = [m[0] for m in gene_metrics_combi],
		# 		metric2 = [m[1] for m in gene_metrics_combi]
		# 	),type = ['gene'],
		# 	refset = REFSETS),
		# expand(
		# 	expand("plots/dy-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.pdf", zip,
		# 		metric1 = [m[0] for m in cell_metrics_combi],
		# 		metric2 = [m[1] for m in cell_metrics_combi]
		# 	),type = ['cell'],
	 	# 	refset = REFSETS),





 		# qc_dirs, ks_dirs
# 		expand(expand(
# 			"results/dy-{{refset}},{metric1},{metric2}.rds", zip,
# 			metric1 = [m[0] for m in gene_metrics],
# 			metric2 = [m[1] for m in gene_metrics]),
# 			refset = REFSETS)#,
# 		expand(expand(
# 			"results/dy-{{refset}},{metric1},{metric2}.rds", zip,
# 			metric1 = [m[0] for m in cell_metrics],
# 			metric2 = [m[1] for m in cell_metrics]),
# 			refset = REFSETS),
		# expand(expand(
		# 	"plots/dy-{{refset}},{metric1},{metric2}.pdf", zip,
		# 	metric1 = [m[0] for m in gene_metrics], 
		# 	metric2 = [m[1] for m in gene_metrics]),
		# 	refset = REFSETS),
		# expand(expand(
		# 	"plots/dy_boxplot-{{refset}},{metric1},{metric2}.pdf", zip,
		# 	metric1 = [m[0] for m in gene_metrics], 
		# 	metric2 = [m[1] for m in gene_metrics]),
		# 	refset = REFSETS)

# ------------------------------------------------------------------------------

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
	output:	"data/02-sub/{datset},{subset}.rds"
	log:	"logs/02-sub_data-{datset},{subset}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fil={input.fil} con={params.con} sub={output}" {input[0]} {log}'''

# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# helenas code
# rule qc_ref:
# 	priority: 1
# 	input:	"code/05-calc_qc.R",
# 			sce = "data/02-sub/{refset}.rds",
# 	params: fun = lambda wc: METRICS[wc.metric]["fun"].replace(" ", "")
# 	output:	"results/qc-{refset},{metric}.rds"
# 	log:	"logs/05-qc_ref-{refset},{metric}.Rout"
# 	shell: 	'''
# 	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
# 	sce={input.sce} fun={params.fun} res={output}" {input[0]} {log}'''
#
# rule qc_sim:
# 	priority: 1
# 	input:	"code/05-calc_qc.R",
# 			sce = rules.sim_data.output
# 	params: fun = lambda wc: METRICS[wc.metric]["fun"].replace(" ", "")
# 	output:	"results/qc-{refset},{metric},{method}.rds"
# 	log:	"logs/05-qc_sim-{refset},{metric},{method}.Rout"
# 	shell: 	'''
# 	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
# 	sce={input.sce} fun={params.fun} res={output}" {input[0]} {log}'''

rule qc_ref:
	priority: 1
	input: "code/05-{type}_qc-{metric}.R",
			sce = "data/02-sub/{refset}.rds"
	output: "results/qc_ref-{refset},{type}_{metric}.rds"
	log: "logs/05_qc_ref-{refset},{type}_{metric}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args sce={input.sce} res={output}" {input[0]} {log}
	'''
# rule qc_ref:
# 	priority: 1
# 	input: "code/05-calc_qc.R",
# 			sce = "data/02-sub/{refset}.rds"
# 	output: "results/qc_ref-{refset},{type}_{metric}.rds"
# 	log: "logs/05_qc_ref-{refset},{type}_{metric}.Rout"
# 	shell: '''
# 	{R} CMD BATCH --no-restore --no-save "--args sce={input.sce} res={output}" {input[0]} {log}
# 	'''

rule qc_sim:
	input: "code/05-{type}_qc-{metric}.R",
			sce = rules.sim_data.output
	output: "results/qc_sim-{refset},{type}_{metric},{method}.rds"
	log: "logs/05-qc_sim-{refset},{type}_{metric},{method}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input.sce} res={output}" {input[0]} {log}'''


rule calc_ks:
	input: "code/05-calc_ks.R",
			ref = rules.qc_ref.output,
			sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset,wc.type, wc.metric) in x] # {refset},{{type}}_{{metric}}
	params: lambda wc, input: ";".join(input.sim)
	output: "results/ks-{refset},{type}_{metric}.rds"
	log: "logs/05-calc_ks-{refset},{type}_{metric}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	ref={input.ref} sim={params} res={output}" {input[0]} {log}'''



# rule calc_ks:
# 	input:	"code/05-calc_ks.R",
# 			ref = rules.qc_ref.output,
# 			sim = lambda wc: [x for x in qc_dirs \
# 				if "{},{}".format(wc.refset,wc.metric) in x]
# 	params: lambda wc, input: ";".join(input.sim)
# 	output:	"results/ks-{refset},{metric}.rds"
# 	log:	"logs/05-calc_ks-{refset},{metric}.Rout"
# 	shell: 	'''
# 	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
# 	ref={input.ref} sim={params} res={output}" {input[0]} {log}'''
#
# rule calc_dy:
# 	input:	"code/05-calc_dy.R",
# 			x_ref = "results/qc-{refset},{metric1}.rds",
# 			y_ref = "results/qc-{refset},{metric2}.rds",
# 			x_sim = lambda wc: [x for x in qc_dirs \
# 				if "{},{}".format(wc.refset,wc.metric1) in x],
# 			y_sim = lambda wc: [x for x in qc_dirs \
# 				if "{},{}".format(wc.refset,wc.metric2) in x]
# 	params: x_sim = lambda wc, input: ";".join(input.x_sim),
# 			y_sim = lambda wc, input: ";".join(input.y_sim)
# 	output:	"results/dy-{refset},{metric1},{metric2}.rds"
# 	log:	"logs/05-calc_dy-{refset},{metric1},{metric2}.Rout"
# 	shell:	'''
# 	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
# 	x_ref={input.x_ref} y_ref={input.y_ref}\
# 	x_sim={params.x_sim} y_sim={params.y_sim}\
# 	res={output}" {input[0]} {log}'''
#
rule calc_emd:
	input:	"code/05-calc_{comp_metric}.R",
			x_ref = "results/qc_ref-{refset},{type}_{metric1}.rds",
			y_ref = "results/qc_ref-{refset},{type}_{metric2}.rds",
			x_sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset,wc.type, wc.metric1) in x],
			y_sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset,wc.type, wc.metric2) in x]
	params: x_sim = lambda wc, input: ";".join(input.x_sim),
			y_sim = lambda wc, input: ";".join(input.y_sim)
	output:	"results/{comp_metric}-{refset},{type}_{metric1},{type}_{metric2}.rds"
	log:	"logs/05-calc_{comp_metric}-{refset},{type}_{metric1},{type}_{metric2}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	x_ref={input.x_ref} y_ref={input.y_ref}\
	x_sim={params.x_sim} y_sim={params.y_sim}\
	res={output}" {input[0]} {log}'''

# ------------------------------------------------------------------------------
#
rule plot_ks_sum:
	input: "code/06-plot_ks_sum.R",
			res = ks_dirs
	params: lambda wc, input: ";".join(input.res)
	output: "plots/ks_summary_{refset}.pdf"
	log: "logs/06-plot_ks_summary_{refset}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	res={params} fig={output}" {input[0]} {log}'''

rule plot_ks_summary:
	input:	"code/06-plot_ks_summary.R",
			res = ks_dirs
	params: lambda wc, input: ";".join(input.res)
	output:	"plots/ks.pdf"
	log:	"logs/06-plot_ks.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	res={params} fig={output}" {input[0]} {log}'''

rule plot_qc:
	input: "code/05-plot_qc.R",
	 		ref = rules.qc_ref.output, \
	  		sim = lambda wc: [x for x in qc_sim_dirs \
						if "{},{}_{}".format(wc.refset,wc.type,wc.metric) in x]
	params: lambda wc, input: ";".join(input.sim)
	output: "plots/qc_{refset},{type}_{metric}.pdf"
	log: "logs/05-plot_qc-{refset},{type}_{metric}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	ref={input.ref} sim={params} fig={output}" {input[0]} {log}'''


# rule plot_dy:
# 	input:	"code/06-plot_dy.R",
# 			res = rules.calc_dy.output
# 	output:	"plots/dy-{refset},{type}_{metric1},{type}_{metric2}.pdf"
# 	log:	"logs/06-plot_dy-{refset},{type}_{metric1},{type}_{metric2}.Rout"
# 	shell: 	'''
# 	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
# 	res={input.res} fig={output}" {input[0]} {log}'''
#
# rule plot_dy_boxplot:
# 	input:	"code/06-plot_dy_boxplot.R",
# 			res = rules.calc_dy.output
# 	output:	"plots/dy_boxplot-{refset},{metric1},{metric2}.pdf"
# 	log:	"logs/06-plot_dy_boxplot-{refset},{metric1},{metric2}.Rout"
# 	shell: 	'''
# 	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
# 	res={input.res} fig={output}" {input[0]} {log}'''