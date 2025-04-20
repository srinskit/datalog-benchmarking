targets=(
	# Format for target specification
	# program	dataset_group	dataset	output-relation	engines	threads
	# program:
	# dataset_group:
	# dataset:
	# output-relation:
	# engines:
	# threads:

	# Fast runs
	# "doop/xalan		doop 	xalan		SubtypeOf DFRScSi 64,4"
	# "doop/batik		doop 	batik		SubtypeOf DFRScSi 64,4"
	# "doop/zxing		doop 	zxing		SubtypeOf DFRScSi 64,4"
	# "doop/biojava	doop	biojava		SubtypeOf DFRScSi 64,4"
	# "doop/eclipse	doop	eclipse		SubtypeOf DFRScSi 64,4"

	# "sg graph-traverse G10K-0.001		Sg DFRScSi 64,4"
	# "sg graph-traverse G5K-0.001		Sg DFRScSi 64,4"
	# "sg graph-traverse wiki-vote		Sg DFRScSi 64,4"

	# "tc graph-traverse G10K-0.001		Tc DFRScSi 64,4"
	# "tc graph-traverse G5K-0.001		Tc DFRScSi 64,4"
	# "tc graph-traverse wiki-vote		Tc DFRScSi 64,4"

	# "dyck graph-traverse kernel		Dyck DFRScSi 64,4"
	# "dyck graph-traverse postgre	Dyck DFRScSi 64,4"

	"reach graph-reach arabic		Reach DFRScSi 64,4"
	"reach graph-reach twitter		Reach DFRScSi 64,4"
	# "reach graph-reach livejournal	Reach DFRScSi 64,4"
	# "reach graph-reach orkut			Reach DFRScSi 64,4"
	# "reach graph-reach wiki-vote		Reach DFRScSi 64,4"

	# "bipartite graph-reach yelp		Zero DFRScSi 64,4"
	# "bipartite graph-reach netflix	Zero DFRScSi 64,4"
	# "bipartite graph-reach mind		Zero DFRScSi 64,4"

	# "diamond	graph-reach	livejournal	Reach	DFRScSi	64,4"
	# "diamond	graph-reach	orkut		Reach	DFRScSi	64,4"
	# "diamond	graph-reach	wiki-vote	Reach	DFRScSi	64,4"
	# "diamond	graph-reach	web-google	Reach	DFRScSi	64,4"

	# "andersen andersen 500000 PointsTo DFRScSi 64,4"
	"andersen andersen 1000000 PointsTo DFRScSi 64,4"

	# "csda csda httpd		NullNode DFRScSi 64,4"
	# "csda csda linux		NullNode DFRScSi 64,4"
	# "csda csda postgresql	NullNode DFRScSi 64,4"

	# "cspa cspa httpd		ValueFlow DFRScSi 64,4"
	# "cspa cspa linux		ValueFlow DFRScSi 64,4"
	# "cspa cspa postgresql	ValueFlow DFRScSi 64,4"

	# "galen misc galen OutP DFRScSi 64,4"

	# "borrow pl borrow path_maybe_initialized_on_exit DFRScSi 64,4"

	# "crdt		pl crdt nextSiblingAnc DFRScSi 64,4"
	# "crdtslow	pl crdt nextSiblingAnc DFRScSi 64,4"

	# "ddisasm/cvc5	pl	cvc5	Stack_def_use_live_var_at_block_end	DRF1ScSi	64"
	# "ddisasm/z3		pl	z3		Stack_def_use_live_var_at_block_end	DRF1ScSi	64"

	# Slow runs
	# "sg graph-traverse G10K-0.01	Sg DFRScSi 64,4"
	# "sg graph-traverse G10K-0.1	Sg DFRScSi 64,4"
	# "sg graph-traverse G20K-0.001	Sg DFRScSi 64,4"
	# "sg graph-traverse G40K-0.001	Sg DFRScSi 64,4"
	# "sg graph-traverse G80K-0.001	Sg DFRScSi 64,4"

	# "tc graph-traverse G10K-0.01	Tc DFRScSi 64,4"
	# "tc graph-traverse G10K-0.1	Tc DFRScSi 64,4"
	# "tc graph-traverse G20K-0.001	Tc DFRScSi 64,4"
	# "tc graph-traverse G40K-0.001	Tc DFRScSi 64,4"
	# "tc graph-traverse G80K-0.001	Tc DFRScSi 64,4"

	# "sg graph-traverse web-stanford	Sg DFRScSi 64,4"
	# "sg graph-traverse web-google		Sg DFRScSi 64,4"
	# "sg graph-traverse web-notredame	Sg DFRScSi 64,4"
	# "sg graph-traverse soc-epinions	Sg DFRScSi 64,4"

	# "tc graph-traverse web-stanford	Tc DFRScSi 64,4"
	# "tc graph-traverse web-google		Tc DFRScSi 64,4"
	# "tc graph-traverse web-notredame	Tc DFRScSi 64,4"
	# "tc graph-traverse soc-epinions	Tc DFRScSi 64,4"

	# Plans
	# "galen/g1	misc galen OutP FScSi 64,4,1"
	# "galen/g2	misc galen OutP FScSi 64,4,1"
	# "galen/g3	misc galen OutP FScSi 64,4,1"
	# "galen/g4	misc galen OutP FScSi 64,4,1"
	# "galen/g5	misc galen OutP FScSi 64,4,1"
	# "galen/g6	misc galen OutP FScSi 64,4,1"
	# "galen/g7	misc galen OutP FScSi 64,4,1"
	# "galen/g8	misc galen OutP FScSi 64,4,1"
	# "galen/g9	misc galen OutP FScSi 64,4,1"
	# "galen/g10	misc galen OutP FScSi 64,4,1"
	# "galen/g11	misc galen OutP FScSi 64,4,1"
	# "galen/g12	misc galen OutP FScSi 64,4,1"
	# "galen/g13	misc galen OutP FScSi 64,4,1"
	# "galen/g14	misc galen OutP FScSi 64,4,1"
	# "galen/g15	misc galen OutP FScSi 64,4,1"
	# "galen/g16	misc galen OutP FScSi 64,4,1"
	# "galen/g17	misc galen OutP FScSi 64,4,1"
	# "galen/g18	misc galen OutP FScSi 64,4,1"

	# "galen/g1-opt	misc galen OutP F 64"
	# "galen/g2-opt	misc galen OutP F 64"
	# "galen/g3-opt	misc galen OutP F 64"
	# "galen/g4-opt	misc galen OutP F 64"
	# "galen/g5-opt	misc galen OutP F 64"
	# "galen/g6-opt	misc galen OutP F 64"
	# "galen/g7-opt	misc galen OutP F 64"
	# "galen/g8-opt	misc galen OutP F 64"
	# "galen/g9-opt	misc galen OutP F 64"
	# "galen/g10-opt	misc galen OutP F 64"
	# "galen/g11-opt	misc galen OutP F 64"
	# "galen/g12-opt	misc galen OutP F 64"
	# "galen/g13-opt	misc galen OutP F 64"
	# "galen/g14-opt	misc galen OutP F 64"
	# "galen/g15-opt	misc galen OutP F 64"
	# "galen/g16-opt	misc galen OutP F 64"
	# "galen/g17-opt	misc galen OutP F 64"
	# "galen/g18-opt	misc galen OutP F 64"

	# "diamond/dr1		graph-reach	web-google	Reach	FScSi	64"
	# "diamond/dr2		graph-reach	web-google	Reach	FScSi	64"
	# "diamond/dr3		graph-reach	web-google	Reach	FScSi	64"
	# "diamond/dr4		graph-reach	web-google	Reach	FScSi	64"
	# "diamond/dr5		graph-reach	web-google	Reach	FScSi	64"
	# "diamond/dr6		graph-reach	web-google	Reach	FScSi	64"
	# "diamond/dr7		graph-reach	web-google	Reach	FScSi	64"
	# "diamond/dr8		graph-reach	web-google	Reach	FScSi	64"
	# "diamond/dr1-opt	graph-reach	web-google	Reach	F		64"
	# "diamond/dr2-opt	graph-reach	web-google	Reach	F		64"
	# "diamond/dr3-opt	graph-reach	web-google	Reach	F		64"
	# "diamond/dr4-opt	graph-reach	web-google	Reach	F		64"
	# "diamond/dr5-opt	graph-reach	web-google	Reach	F		64"
	# "diamond/dr6-opt	graph-reach	web-google	Reach	F		64"
	# "diamond/dr7-opt	graph-reach	web-google	Reach	F		64"
	# "diamond/dr8-opt	graph-reach	web-google	Reach	F		64"

	# "doop/doop-0		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-1		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-2		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-3		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-4		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-5		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-6		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-7		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-8		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-9		doop 	batik	SubtypeOf FScSi	64"
	# "doop/doop-10		doop 	batik	SubtypeOf FScSi	64"

	# "doop/doop-0-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-1-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-2-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-3-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-4-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-5-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-6-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-7-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-8-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-9-opt	doop 	batik	SubtypeOf F		64"
	# "doop/doop-10-opt	doop 	batik	SubtypeOf F		64"

	# Scalability
	# "crdt		pl			crdt nextSiblingAnc DFRScSi 64,32,16,8,4,2,1 1800s"
	# "borrow		pl			borrow path_maybe_initialized_on_exit DFRScSi 64,32,16,8,4,2,1 1800s"
	# "cspa		cspa		postgresql	ValueFlow DFRScSi 64,32,16,8,4,2,1 1800s"
	# "csda		csda postgresql	NullNode DFRScSi 64,32,16,8,4,2,1 1800s"
	# "csda		csda linux	NullNode DFRScSi 64,32,16,8,4,2,1 1800s"
	# "andersen	andersen 500000 PointsTo DFRScSi 64,32,16,8,4,2,1 1800s"
	# "bipartite	graph-reach mind		Zero DFRScSi 64,32,16,8,4,2,1 1800s"
	# "reach		graph-reach livejournal	Reach DFRScSi 64,32,16,8,4,2,1 1800s"
	# "dyck		graph-traverse postgre	Dyck DFRScSi 64,32,16,8,4,2,1 1800s"
	# "tc			graph-traverse G10K-0.001		Tc DFRScSi 64,32,16,8,4,2,1 1800s"
	# "sg			graph-traverse G10K-0.001		Sg DFRScSi 64,32,16,8,4,2,1 1800s"
	# "ddisasm/z3		pl	z3		Stack_def_use_live_var_at_block_end	DFRScSi	64,32,16,8,4,2,1 1800s"
	"bipartite graph-reach netflix	Zero DFRScSi 64,32,16,8,4,2,1 1800s"
)
