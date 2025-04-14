targets=(
	# # Fast
	"doop/xalan		doop 	xalan		SubtypeOf DERScSi"
	"doop/batik		doop 	batik		SubtypeOf DERScSi"
	"doop/zxing		doop 	zxing		SubtypeOf DERScSi"
	"doop/biojava	doop	biojava		SubtypeOf DERScSi"
	"doop/eclipse	doop	eclipse		SubtypeOf DERScSi"

	"sg graph-traverse G10K-0.001		Sg DERScSi"
	"sg graph-traverse G5K-0.001		Sg DERScSi"
	"sg graph-traverse wiki-vote		Sg DERScSi"

	"tc graph-traverse G10K-0.001		Tc DERScSi"
	"tc graph-traverse G5K-0.001		Tc DERScSi"
	"tc graph-traverse wiki-vote		Tc DERScSi"

	"dyck graph-traverse kernel		Dyck DERScSi"
	"dyck graph-traverse postgre	Dyck DERScSi"

	"reach graph-reach livejournal	Reach DERScSi"
	"reach graph-reach orkut			Reach DERScSi"
	"reach graph-reach wiki-vote		Reach DERScSi"

	"bipartite graph-reach yelp		Zero DERScSi"
	"bipartite graph-reach netflix	Zero DERScSi"
	"bipartite graph-reach mind		Zero DERScSi"

	"diamond graph-reach livejournal	Reach DERScSi"
	"diamond graph-reach orkut		Reach DERScSi"
	"diamond graph-reach wiki-vote	Reach DERScSi"

	"andersen andersen 500000 PointsTo DERScSi"

	"csda csda httpd		NullNode DERScSi"
	"csda csda linux		NullNode DERScSi"
	"csda csda postgresql	NullNode DERScSi"

	"cspa cspa httpd		ValueFlow DERScSi"
	"cspa cspa linux		ValueFlow DERScSi"
	"cspa cspa postgresql	ValueFlow DERScSi"

	"galen misc galen OutP DEScSi"

	"borrow pl borrow path_maybe_initialized_on_exit DERScSi"

	"crdt		pl crdt nextSiblingAnc DERScSi"
	"crdtslow	pl crdt nextSiblingAnc DERScSi"

	# Slow
	"sg graph-traverse G10K-0.01	Sg DERScSi"
	"sg graph-traverse G10K-0.1	Sg DERScSi"
	"sg graph-traverse G20K-0.001	Sg DERScSi"
	"sg graph-traverse G40K-0.001	Sg DERScSi"
	"sg graph-traverse G80K-0.001	Sg DERScSi"

	"tc graph-traverse G10K-0.01	Tc DERScSi"
	"tc graph-traverse G10K-0.1	Tc DERScSi"
	"tc graph-traverse G20K-0.001	Tc DERScSi"
	"tc graph-traverse G40K-0.001	Tc DERScSi"
	"tc graph-traverse G80K-0.001	Tc DERScSi"

	"sg graph-traverse web-stanford	Sg DERScSi"
	"sg graph-traverse web-google		Sg DERScSi"
	"sg graph-traverse web-notredame	Sg DERScSi"
	"sg graph-traverse soc-epinions	Sg DERScSi"

	"tc graph-traverse web-stanford	Tc DERScSi"
	"tc graph-traverse web-google		Tc DERScSi"
	"tc graph-traverse web-notredame	Tc DERScSi"
	"tc graph-traverse soc-epinions	Tc DERScSi"

	# Plans
	"galen/g1 misc pl OutP EScSi"
	"galen/g2 misc pl OutP EScSi"
	"galen/g3 misc pl OutP EScSi"
	"galen/g4 misc pl OutP EScSi"
	"galen/g5 misc pl OutP EScSi"
	"galen/g6 misc pl OutP EScSi"
	"galen/g7 misc pl OutP EScSi"
	"galen/g8 misc pl OutP EScSi"
	"galen/g9 misc pl OutP EScSi"
	"galen/g10 misc pl OutP EScSi"
	"galen/g11 misc pl OutP EScSi"
	"galen/g12 misc pl OutP EScSi"
	"galen/g13 misc pl OutP EScSi"
	"galen/g14 misc pl OutP EScSi"
	"galen/g15 misc pl OutP EScSi"
	"galen/g16 misc pl OutP EScSi"
	"galen/g17 misc pl OutP EScSi"
	"galen/g18 misc pl OutP EScSi"

	"diamond-reach/dr1-opt		gt web-stanford DiamondReach E"
	"diamond-reach/dr1-plan		gt web-stanford DiamondReach E"
	"diamond-reach/dr1-sip		gt web-stanford DiamondReach E"
	"diamond-reach/dr3-opt		gt web-stanford DiamondReach E"
	"diamond-reach/dr3-plan		gt web-stanford DiamondReach E"
	"diamond-reach/dr3-sip		gt web-stanford DiamondReach E"
	"diamond-reach/dr-cp1-plan	gt web-stanford DiamondReach E"

	"diamond-reach/dr1			gt web-stanford DiamondReach EScSi"
	"diamond-reach/dr2			gt web-stanford DiamondReach EScSi"
	"diamond-reach/dr3			gt web-stanford DiamondReach EScSi"
	"diamond-reach/dr4			gt web-stanford DiamondReach EScSi"
	"diamond-reach/dr5			gt web-stanford DiamondReach EScSi"
	"diamond-reach/dr6			gt web-stanford DiamondReach EScSi"

	"diamond-reach/dr1-opt		gt web-google DiamondReach E"
	"diamond-reach/dr1-plan		gt web-google DiamondReach E"
	"diamond-reach/dr1-sip		gt web-google DiamondReach E"
	"diamond-reach/dr3-opt		gt web-google DiamondReach E"
	"diamond-reach/dr3-plan		gt web-google DiamondReach E"
	"diamond-reach/dr3-sip		gt web-google DiamondReach E"
	"diamond-reach/dr-cp1-plan	gt web-google DiamondReach E"

	"diamond-reach/dr1			gt web-google DiamondReach EScSi"
	"diamond-reach/dr2			gt web-google DiamondReach EScSi"
	"diamond-reach/dr3			gt web-google DiamondReach EScSi"
	"diamond-reach/dr4			gt web-google DiamondReach EScSi"
	"diamond-reach/dr5			gt web-google DiamondReach EScSi"
	"diamond-reach/dr6			gt web-google DiamondReach EScSi"
)

workers=(64 4 1)
