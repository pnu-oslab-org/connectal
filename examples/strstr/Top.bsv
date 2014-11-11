// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;

// portz libraries
import CtrlMux::*;
import Portal::*;
import Leds::*;
import ConnectalMemory::*;
import MemTypes::*;
import MemServer::*;
import MMU::*;

// generated by tool
import StrstrRequest::*;
import MemServerRequest::*;
import MMURequest::*;
import StrstrIndication::*;
import MemServerIndication::*;
import MMUIndication::*;

// defined by user
import Strstr::*;

typedef enum {StrstrIndication, StrstrRequest, HostMemServerIndication, HostMemServerRequest, HostMMURequest, HostMMUIndication} IfcNames deriving (Eq,Bits);

module mkConnectalTop(StdConnectalDmaTop#(PhysAddrWidth));

   StrstrIndicationProxy strstrIndicationProxy <- mkStrstrIndicationProxy(StrstrIndication);
   Strstr#(64) strstr <- mkStrstr(strstrIndicationProxy.ifc);
   StrstrRequestWrapper strstrRequestWrapper <- mkStrstrRequestWrapper(StrstrRequest,strstr.request);
   
   let readClients = cons(strstr.config_read_client, strstr.haystack_read_clients);
   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(HostMMUIndication);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUIndicationProxy.ifc);
   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(HostMMURequest, hostMMU.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(HostMemServerIndication);
   MemServer#(PhysAddrWidth,64,1) dma <- mkMemServerR(hostMemServerIndicationProxy.ifc, readClients, cons(hostMMU,nil));
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(HostMemServerRequest, dma.request);

   Vector#(6,StdPortal) portals;
   portals[0] = strstrRequestWrapper.portalIfc;
   portals[1] = strstrIndicationProxy.portalIfc; 
   portals[2] = hostMemServerRequestWrapper.portalIfc;
   portals[3] = hostMemServerIndicationProxy.portalIfc; 
   portals[4] = hostMMURequestWrapper.portalIfc;
   portals[5] = hostMMUIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
   interface leds = default_leds;
endmodule
