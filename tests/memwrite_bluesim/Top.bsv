// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import PCIE::*;

// portz libraries
import Leds::*;
import CtrlMux::*;
import Portal::*;
import ConnectalMemory::*;
import MemTypes::*;
import MemServer::*;
import MMU::*;
import HostInterface::*;
import MemSlaveEngine::*;

// generated by tool
import MemwriteRequest::*;
import MemServerRequest::*;
import MMURequest::*;
import MemwriteIndication::*;
import MemServerIndication::*;
import MMUIndication::*;

// defined by user
import Memwrite::*;

typedef enum {HostMemServerIndication, HostMemServerRequest, HostMMURequest, HostMMUIndication, MemwriteIndication, MemwriteRequest} IfcNames deriving (Eq,Bits);

module mkConnectalTop(ConnectalTop#(PhysAddrWidth,DataBusWidth,Empty,1));

   MemwriteIndicationProxy memwriteIndicationProxy <- mkMemwriteIndicationProxy(MemwriteIndication);
   Memwrite memwrite <- mkMemwrite(memwriteIndicationProxy.ifc);
   MemwriteRequestWrapper memwriteRequestWrapper <- mkMemwriteRequestWrapper(MemwriteRequest,memwrite.request);

   Vector#(1, MemWriteClient#(DataBusWidth)) writeClients = cons(memwrite.dmaClient,nil);
   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(HostMMUIndication);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUIndicationProxy.ifc);
   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(HostMMURequest, hostMMU.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(HostMemServerIndication);
   MemServer#(PhysAddrWidth,DataBusWidth,1) dma <- mkMemServerW(hostMemServerIndicationProxy.ifc, writeClients, cons(hostMMU,nil));
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(HostMemServerRequest, dma.request);

   MemMaster#(PhysAddrWidth,DataBusWidth) dma1 = (interface MemMaster;
	  interface MemReadClient read_client;
	     interface Get readReq;
		method ActionValue#(PhysMemRequest#(PhysAddrWidth)) get() if (False);
		   return ?;
	        endmethod
	     endinterface
	  endinterface
	  interface MemWriteClient write_client;
	     interface Get writeReq;
		method ActionValue#(PhysMemRequest#(PhysAddrWidth)) get() if (False);
		   return ?;
	        endmethod
	     endinterface
	  endinterface
      endinterface);

   Reg#(Bit#(32)) cycles <- mkReg(0);
   Reg#(Bit#(32)) reqCycles <- mkReg(0);
   Reg#(Bit#(32)) dataCycles <- mkReg(0);
   rule count;
      cycles <= cycles + 1;
   endrule

   rule startdump if (cycles == 1);
      $dumpvars();
   endrule

   rule finish if (reqCycles == 10000);
      $dumpoff();
   endrule

   MemSlaveEngine#(DataBusWidth) memSlaveEngine <- mkMemSlaveEngine(PciId {bus: 4, dev: 2, func: 0});
   mkConnection(dma.masters[0], memSlaveEngine.slave);

   rule displayTlp;
      let tlp <- memSlaveEngine.tlp.request.get();
      TLPMemory4DWHeader hdr4dw = unpack(tlp.data);
      TLPMemoryIO3DWHeader hdr3dw = unpack(tlp.data);
      let newReqCycles = reqCycles;
      if (tlp.sof && hdr4dw.format == MEM_WRITE_4DW_DATA) begin
	 $display("%d 4dw req %h %d", cycles-reqCycles, hdr4dw.addr<<2, fromInteger(valueOf(DataBusWidth)));
	 newReqCycles = cycles;
      end
      else if (tlp.sof && hdr3dw.format == MEM_WRITE_3DW_DATA) begin
	 $display("%d 3dw req %h %d", cycles-reqCycles, hdr4dw.addr<<2, fromInteger(valueOf(DataBusWidth)));
	 newReqCycles = cycles;
      end
      else if (tlp.sof) begin
	 $display("%d sof %h", cycles-reqCycles, tlp.data);
	 newReqCycles = cycles;
      end
      else begin
	 $display("%d data %h", cycles-reqCycles, tlp.data);
	 dataCycles <= cycles;
	 newReqCycles = cycles;
      end
      reqCycles <= newReqCycles;
   endrule

   Vector#(6,StdPortal) portals;
   portals[0] = memwriteRequestWrapper.portalIfc;
   portals[1] = memwriteIndicationProxy.portalIfc; 
   portals[2] = hostMemServerRequestWrapper.portalIfc;
   portals[3] = hostMemServerIndicationProxy.portalIfc; 
   portals[4] = hostMMURequestWrapper.portalIfc;
   portals[5] = hostMMUIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = cons(dma1,nil);
   interface leds = default_leds;
endmodule
