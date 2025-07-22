"""Variable number of nodes in a lan. You have the option of picking from one
of several standard images we provide, or just use the default (typically a recent
version of Ubuntu). You may also optionally pick the specific hardware type for
all the nodes in the lan. 

Instructions:
Wait for the experiment to start, and then log into one or more of the nodes
by clicking on them in the toplogy, and choosing the `shell` menu option.
Use `sudo` to run root commands. 
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg
# Emulab specific extensions.
import geni.rspec.emulab as emulab

# Create a portal context, needed to defined parameters
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

bench_os_image = 'urn:publicid:IDN+clemson.cloudlab.us+image+lpad-PG0:dlbench-ubu20-v4.0'
driver_os_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU24-64-STD'

# Optional physical type for benchmark nodes.
pc.defineParameter("benchNodeType",  "Optional benchmark node type",
				   portal.ParameterType.NODETYPE, "r6525",
				   longDescription="Pick a single physical node type (pc3000,d710,etc) " +
				   "instead of letting the resource mapper choose for you.")

# Optional physical type for driver node.
pc.defineParameter("driverNodeType",  "Optional driver node type",
				   portal.ParameterType.NODETYPE, "d710",
				   longDescription="Pick a single physical node type (pc3000,d710,etc) " +
				   "instead of letting the resource mapper choose for you.")

# Optional link speed, normally the resource mapper will choose for you based on node availability
pc.defineParameter("linkSpeed", "Link Speed",portal.ParameterType.INTEGER, 0,
				   [(0,"Any"),(100000,"100Mb/s"),(1000000,"1Gb/s"),(10000000,"10Gb/s"),(25000000,"25Gb/s"),(100000000,"100Gb/s")],
				   advanced=True,
				   longDescription="A specific link speed to use for your lan. Normally the resource " +
				   "mapper will choose for you based on node availability and the optional physical type.")
				   
# For very large lans you might to tell the resource mapper to override the bandwidth constraints
# and treat it a "best-effort"
pc.defineParameter("bestEffort",  "Best Effort", portal.ParameterType.BOOLEAN, False,
					advanced=True,
					longDescription="For very large lans, you might get an error saying 'not enough bandwidth.' " +
					"This options tells the resource mapper to ignore bandwidth and assume you know what you " +
					"are doing, just give me the lan I ask for (if enough nodes are available).")
					
# Sometimes you want all of nodes on the same switch, Note that this option can make it impossible
# for your experiment to map.
pc.defineParameter("sameSwitch",  "No Interswitch Links", portal.ParameterType.BOOLEAN, False,
					advanced=True,
					longDescription="Sometimes you want all the nodes connected to the same switch. " +
					"This option will ask the resource mapper to do that, although it might make " +
					"it imppossible to find a solution. Do not use this unless you are sure you need it!")

# Optional ephemeral blockstore
pc.defineParameter("tempFileSystemSize", "Temporary Filesystem Size",
				   portal.ParameterType.INTEGER, 0,advanced=True,
				   longDescription="The size in GB of a temporary file system to mount on each of your " +
				   "nodes. Temporary means that they are deleted when your experiment is terminated. " +
				   "The images provided by the system have small root partitions, so use this option " +
				   "if you expect you will need more space to build your software packages or store " +
				   "temporary files.")
				   
# Instead of a size, ask for all available space. 
pc.defineParameter("tempFileSystemMax",  "Temp Filesystem Max Space",
					portal.ParameterType.BOOLEAN, False,
					advanced=True,
					longDescription="Instead of specifying a size for your temporary filesystem, " +
					"check this box to allocate all available disk space. Leave the size above as zero.")

pc.defineParameter("tempFileSystemMount", "Temporary Filesystem Mount Point",
				   portal.ParameterType.STRING,"/mydata",advanced=True,
				   longDescription="Mount the temporary file system at this mount point; in general you " +
				   "you do not need to change this, but we provide the option just in case your software " +
				   "is finicky.")

pc.defineParameter("exclusiveVMs", "Force use of exclusive VMs",
				   portal.ParameterType.BOOLEAN, True,
				   advanced=True,
				   longDescription="When True and useVMs is specified, setting this will force allocation " +
				   "of exclusive VMs. When False, VMs may be shared or exclusive depending on the policy " +
				   "of the cluster.")

pc.defineParameter("remoteDataset", "URN of your remote dataset", 
				   portal.ParameterType.STRING,
				   "urn:publicid:IDN+clemson.cloudlab.us:lpad-pg0+ltdataset+dldataset")

# Retrieve the values the user specifies during instantiation.
params = pc.bindParameters()

# Check parameter validity.
if params.nodeCount < 1:
	pc.reportError(portal.ParameterError("You must choose at least 1 node.", ["nodeCount"]))

if params.tempFileSystemSize < 0 or params.tempFileSystemSize > 200:
	pc.reportError(portal.ParameterError("Please specify a size greater then zero and " +
										 "less then 200GB", ["tempFileSystemSize"]))

if params.benchNodeType != "":
	tokens = params.benchNodeType.split(",")
	if len(tokens) != 1:
		pc.reportError(portal.ParameterError("Only a single type is allowed", ["benchNodeType"]))

pc.verifyParameters()

makelan = False

if params.nodeCount == 1:
	lan = request.Link()
else:
	lan = request.LAN()

if params.bestEffort:
	lan.best_effort = True
elif params.linkSpeed > 0:
	lan.bandwidth = params.linkSpeed
if params.sameSwitch:
	lan.setNoInterSwitchLinks()

# The remote file system is represented by special node.
fsnode = request.RemoteBlockstore("fsnode", "/remote")
# This URN is displayed in the web interfaace for your dataset.
fsnode.dataset = params.remoteDataset
fsnode.readonly = True

fslink = request.Link("fslink")
fslink.addInterface(fsnode.interface)
# Special attributes for this link that we must use.
fslink.best_effort = True
fslink.vlan_tagging = True
	
# Process nodes, adding to link or lan.
for i in range(params.nodeCount):
	# Create a node and add it to the request
	name = "node" + str(i)
	node = request.RawPC(name)
	node.disk_image = bench_os_image

	bs = node.Blockstore(name + "-data-bs", "/data")
	bs.size = "300GB"
	
	# We need a link to talk to the remote file system, so make an interface.
	fsiface = node.addInterface()
	fslink.addInterface(fsiface)

	# Add to lan
	iface = node.addInterface("eth1")
	lan.addInterface(iface)

	# Optional hardware type.
	if params.benchNodeType != "":
		node.hardware_type = params.benchNodeType

	# Optional Blockstore
	if params.tempFileSystemSize > 0 or params.tempFileSystemMax:
		bs = node.Blockstore(name + "-bs", params.tempFileSystemMount)
		if params.tempFileSystemMax:
			bs.size = "0GB"
		else:
			bs.size = str(params.tempFileSystemSize) + "GB"

		bs.placement = "any"


# Create the driver node
name = "noded"
node = request.RawPC(name)
node.disk_image = driver_os_image

iface = node.addInterface("eth1")
lan.addInterface(iface)

# Optional hardware type.
if params.driverNodeType != "":
	node.hardware_type = params.driverNodeType

# Print the RSpec to the enclosing page.
pc.printRequestRSpec(request)
