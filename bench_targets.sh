targets=(
	# Fast
	"xalan doop xalan SubtypeOf EScSi"
	"batik doop batik SubtypeOf EScSi"
	"zxing doop zxing SubtypeOf EScSi"
	"biojava doop biojava SubtypeOf EScSi"
	"eclipse doop eclipse SubtypeOf EScSi"

	"sg gt G10K-0.001 Sg DERScSi"
	"sg gt G5K-0.001 Sg DERScSi"

	"tc gt G10K-0.001 Tc DERScSi"
	"tc gt G5K-0.001 Tc DERScSi"

	"reach ga livejournal Reach DERScSi"
	"reach ga orkut Reach DERScSi"

	"andersen andersen 500000 PointsTo DERScSi"

	"csda csda httpd Null DERScSi"
	"csda csda linux Null DERScSi"
	"csda csda postgresql Null DERScSi"
	"cspa cspa httpd ValueFlow DERScSi"
	"cspa cspa linux ValueFlow DERScSi"
	"cspa cspa postgresql ValueFlow DERScSi"

	"galen misc galen OutP DEScSi"

	# Slow
	# "sg gt G10K-0.01 Sg DERScSi"
	# "sg gt G10K-0.1 Sg DERScSi"
	# "sg gt G20K-0.001 Sg DERScSi"
	# "sg gt G40K-0.001 Sg DERScSi"
	# "sg gt G80K-0.001 Sg DERScSi"
	# "tc gt G10K-0.01 Tc DERScSi"
	# "tc gt G10K-0.1 Tc DERScSi"
	# "tc gt G20K-0.001 Tc DERScSi"
	# "tc gt G40K-0.001 Tc DERScSi"
	# "tc gt G80K-0.001 Tc DERScSi"
)

# workers=(64)
workers=(64 4)
