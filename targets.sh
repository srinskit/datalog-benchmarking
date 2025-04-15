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
	"doop/xalan		doop 	xalan		SubtypeOf DERScSi 64,4"
	"doop/batik		doop 	batik		SubtypeOf DERScSi 64,4"
	"doop/zxing		doop 	zxing		SubtypeOf DERScSi 64,4"
	"doop/biojava	doop	biojava		SubtypeOf DERScSi 64,4"
	"doop/eclipse	doop	eclipse		SubtypeOf DERScSi 64,4"

	"sg graph-traverse G10K-0.001		Sg DERScSi 64,4"
	"sg graph-traverse G5K-0.001		Sg DERScSi 64,4"
	"sg graph-traverse wiki-vote		Sg DERScSi 64,4"

	"tc graph-traverse G10K-0.001		Tc DERScSi 64,4"
	"tc graph-traverse G5K-0.001		Tc DERScSi 64,4"
	"tc graph-traverse wiki-vote		Tc DERScSi 64,4"

	"dyck graph-traverse kernel		Dyck DERScSi 64,4"
	"dyck graph-traverse postgre	Dyck DERScSi 64,4"

	"reach graph-reach livejournal	Reach DERScSi 64,4"
	"reach graph-reach orkut			Reach DERScSi 64,4"
	"reach graph-reach wiki-vote		Reach DERScSi 64,4"

	"bipartite graph-reach yelp		Zero DERScSi 64,4"
	"bipartite graph-reach netflix	Zero DERScSi 64,4"
	"bipartite graph-reach mind		Zero DERScSi 64,4"

	"diamond graph-reach livejournal	Reach DERScSi 64,4"
	"diamond graph-reach orkut		Reach DERScSi 64,4"
	"diamond graph-reach wiki-vote	Reach DERScSi 64,4"

	"andersen andersen 500000 PointsTo DERScSi 64,4"

	"csda csda httpd		NullNode DERScSi 64,4"
	"csda csda linux		NullNode DERScSi 64,4"
	"csda csda postgresql	NullNode DERScSi 64,4"

	"cspa cspa httpd		ValueFlow DERScSi 64,4"
	"cspa cspa linux		ValueFlow DERScSi 64,4"
	"cspa cspa postgresql	ValueFlow DERScSi 64,4"

	"galen misc galen OutP DEScSi 64,4"

	"borrow pl borrow path_maybe_initialized_on_exit DERScSi 64,4"

	"crdt		pl crdt nextSiblingAnc DERScSi 64,4"
	"crdtslow	pl crdt nextSiblingAnc DERScSi 64,4"

	# Slow runs
	"sg graph-traverse G10K-0.01	Sg DERScSi 64,4"
	"sg graph-traverse G10K-0.1	Sg DERScSi 64,4"
	"sg graph-traverse G20K-0.001	Sg DERScSi 64,4"
	"sg graph-traverse G40K-0.001	Sg DERScSi 64,4"
	"sg graph-traverse G80K-0.001	Sg DERScSi 64,4"

	"tc graph-traverse G10K-0.01	Tc DERScSi 64,4"
	"tc graph-traverse G10K-0.1	Tc DERScSi 64,4"
	"tc graph-traverse G20K-0.001	Tc DERScSi 64,4"
	"tc graph-traverse G40K-0.001	Tc DERScSi 64,4"
	"tc graph-traverse G80K-0.001	Tc DERScSi 64,4"

	"sg graph-traverse web-stanford	Sg DERScSi 64,4"
	"sg graph-traverse web-google		Sg DERScSi 64,4"
	"sg graph-traverse web-notredame	Sg DERScSi 64,4"
	"sg graph-traverse soc-epinions	Sg DERScSi 64,4"

	"tc graph-traverse web-stanford	Tc DERScSi 64,4"
	"tc graph-traverse web-google		Tc DERScSi 64,4"
	"tc graph-traverse web-notredame	Tc DERScSi 64,4"
	"tc graph-traverse soc-epinions	Tc DERScSi 64,4"

	# Plans
	"galen/g1 misc galen OutP EScSi 64,4,1"
	"galen/g2 misc galen OutP EScSi 64,4,1"
	"galen/g3 misc galen OutP EScSi 64,4,1"
	"galen/g4 misc galen OutP EScSi 64,4,1"
	"galen/g5 misc galen OutP EScSi 64,4,1"
	"galen/g6 misc galen OutP EScSi 64,4,1"
	"galen/g7 misc galen OutP EScSi 64,4,1"
	"galen/g8 misc galen OutP EScSi 64,4,1"
	"galen/g9 misc galen OutP EScSi 64,4,1"
	"galen/g10 misc galen OutP EScSi 64,4,1"
	"galen/g11 misc galen OutP EScSi 64,4,1"
	"galen/g12 misc galen OutP EScSi 64,4,1"
	"galen/g13 misc galen OutP EScSi 64,4,1"
	"galen/g14 misc galen OutP EScSi 64,4,1"
	"galen/g15 misc galen OutP EScSi 64,4,1"
	"galen/g16 misc galen OutP EScSi 64,4,1"
	"galen/g17 misc galen OutP EScSi 64,4,1"
	"galen/g18 misc galen OutP EScSi 64,4,1"

	"diamond-reach/dr1-opt		gt web-stanford DiamondReach E 64,4"
	"diamond-reach/dr1-plan		gt web-stanford DiamondReach E 64,4"
	"diamond-reach/dr1-sip		gt web-stanford DiamondReach E 64,4"
	"diamond-reach/dr3-opt		gt web-stanford DiamondReach E 64,4"
	"diamond-reach/dr3-plan		gt web-stanford DiamondReach E 64,4"
	"diamond-reach/dr3-sip		gt web-stanford DiamondReach E 64,4"
	"diamond-reach/dr-cp1-plan	gt web-stanford DiamondReach E 64,4"

	"diamond-reach/dr1			gt web-stanford DiamondReach EScSi 64,4"
	"diamond-reach/dr2			gt web-stanford DiamondReach EScSi 64,4"
	"diamond-reach/dr3			gt web-stanford DiamondReach EScSi 64,4"
	"diamond-reach/dr4			gt web-stanford DiamondReach EScSi 64,4"
	"diamond-reach/dr5			gt web-stanford DiamondReach EScSi 64,4"
	"diamond-reach/dr6			gt web-stanford DiamondReach EScSi 64,4"

	"diamond-reach/dr1-opt		gt web-google DiamondReach E 64,4"
	"diamond-reach/dr1-plan		gt web-google DiamondReach E 64,4"
	"diamond-reach/dr1-sip		gt web-google DiamondReach E 64,4"
	"diamond-reach/dr3-opt		gt web-google DiamondReach E 64,4"
	"diamond-reach/dr3-plan		gt web-google DiamondReach E 64,4"
	"diamond-reach/dr3-sip		gt web-google DiamondReach E 64,4"
	"diamond-reach/dr-cp1-plan	gt web-google DiamondReach E 64,4"

	"diamond-reach/dr1			gt web-google DiamondReach EScSi 64,4"
	"diamond-reach/dr2			gt web-google DiamondReach EScSi 64,4"
	"diamond-reach/dr3			gt web-google DiamondReach EScSi 64,4"
	"diamond-reach/dr4			gt web-google DiamondReach EScSi 64,4"
	"diamond-reach/dr5			gt web-google DiamondReach EScSi 64,4"
	"diamond-reach/dr6			gt web-google DiamondReach EScSi 64,4"
)
