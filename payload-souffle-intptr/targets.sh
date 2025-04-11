targets=(
	# Fast
	"xalan		doop 	xalan		SubtypeOf DERScSi"
	"batik		doop 	batik		SubtypeOf DERScSi"
	"zxing		doop 	zxing		SubtypeOf DERScSi"
	"biojava	doop	biojava		SubtypeOf DERScSi"
	"eclipse	doop	eclipse		SubtypeOf DERScSi"

	"sg gt G10K-0.001		Sg DERScSi"
	"sg gt G5K-0.001		Sg DERScSi"
	"sg gt web-stanford		Sg DERScSi"
	"sg gt web-google		Sg DERScSi"
	"sg gt wiki-vote		Sg DERScSi"
	"sg gt web-notredame	Sg DERScSi"
	"sg gt soc-epinions		Sg DERScSi"

	"tc gt G10K-0.001		Tc DERScSi"
	"tc gt G5K-0.001		Tc DERScSi"
	"tc gt web-stanford		Tc DERScSi"
	"tc gt web-google		Tc DERScSi"
	"tc gt wiki-vote		Tc DERScSi"
	"tc gt web-notredame	Tc DERScSi"
	"tc gt soc-epinions		Tc DERScSi"

	"reach ga livejournal	Reach DERScSi"
	"reach ga orkut			Reach DERScSi"
	"reach gt wiki-vote		Reach DERScSi"
	"reach gt simon			Reach DERScSi"

	"andersen andersen 500000 PointsTo DERScSi"

	"csda csda httpd		NullNode DERScSi"
	"csda csda linux		NullNode DERScSi"
	"csda csda postgresql	NullNode DERScSi"

	"cspa cspa httpd		ValueFlow DERScSi"
	"cspa cspa linux		ValueFlow DERScSi"
	"cspa cspa postgresql	ValueFlow DERScSi"

	"galen misc galen OutP DERScSi"

	"borrow pl borrow path_maybe_initialized_on_exit DERScSi"

	"crdt		ga crdt nextSiblingAnc DERScSi"
	"crdtslow	ga crdt nextSiblingAnc DERScSi"

	"bipartite ga yelp		Zero DERScSi"
	"bipartite ga netflix	Zero DERScSi"
	"bipartite ga mind		Zero DERScSi"

	# Slow
	"sg gt G10K-0.01	Sg DERScSi"
	"sg gt G10K-0.1		Sg DERScSi"
	"sg gt G20K-0.001	Sg DERScSi"
	"sg gt G40K-0.001	Sg DERScSi"
	"sg gt G80K-0.001	Sg DERScSi"
	"tc gt G10K-0.01	Tc DERScSi"
	"tc gt G10K-0.1		Tc DERScSi"
	"tc gt G20K-0.001	Tc DERScSi"
	"tc gt G40K-0.001	Tc DERScSi"
	"tc gt G80K-0.001	Tc DERScSi"

	# Plans
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

workers=(64 4)
