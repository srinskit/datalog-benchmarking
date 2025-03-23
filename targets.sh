targets=(
	# Fast
	"xalan doop xalan SubtypeOf DERScSi"
	"batik doop batik SubtypeOf DERScSi"
	"zxing doop zxing SubtypeOf DERScSi"
	"biojava doop biojava SubtypeOf DERScSi"
	"eclipse doop eclipse SubtypeOf DERScSi"

	"sg gt G10K-0.001 Sg DERScSi"
	"sg gt G5K-0.001 Sg DERScSi"

	"tc gt G10K-0.001 Tc DERScSi"
	"tc gt G5K-0.001 Tc DERScSi"

	"reach ga livejournal Reach DERScSi"
	"reach ga orkut Reach DERScSi"

	"andersen andersen 500000 PointsTo DERScSi"

	"csda csda httpd NullNode DERScSi"
	"csda csda linux NullNode DERScSi"
	"csda csda postgresql NullNode DERScSi"
	"cspa cspa httpd ValueFlow DERScSi"
	"cspa cspa linux ValueFlow DERScSi"
	"cspa cspa postgresql ValueFlow DERScSi"

	"galen misc galen OutP DERScSi"
	"borrow pl borrow origin_live_on_entry DERScSi"

	"crdt ga crdt nextSiblingAnc DERScSi"
	"crdtslow ga crdt nextSiblingAnc DERScSi"

	# Slow
	"sg gt G10K-0.01 Sg DERScSi"
	"sg gt G10K-0.1 Sg DERScSi"
	"sg gt G20K-0.001 Sg DERScSi"
	"sg gt G40K-0.001 Sg DERScSi"
	"sg gt G80K-0.001 Sg DERScSi"
	"tc gt G10K-0.01 Tc DERScSi"
	"tc gt G10K-0.1 Tc DERScSi"
	"tc gt G20K-0.001 Tc DERScSi"
	"tc gt G40K-0.001 Tc DERScSi"
	"tc gt G80K-0.001 Tc DERScSi"
)

#workers=(64)
workers=(64 4)
