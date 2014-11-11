// bsv libraries
import Vector::*;
import FIFO::*;
import Connectable::*;
import Portal::*;
import CtrlMux::*;
import Leds::*;
import MemTypes::*;

// generated by tool
import EchoIndication::*;
import EchoRequest::*;
import Swallow::*;

// defined by user
import Echo::*;
import SwallowIF::*;

typedef enum {EchoIndication, EchoRequest, Swallow, MMURequest, MMUIndication} IfcNames deriving (Eq,Bits);

// module mkCntr#(Integer label)(Empty);
//    Reg#(Bit#(32)) cycles <- mkReg(0);
//    rule count;
//       cycles <= cycles+1;
//       $display("mkCntr(%d) %d",label, cycles);
//    endrule
// endmodule

module mkConnectalTop(StdConnectalTop#(PhysAddrWidth));

   // instantiate user portals
   EchoIndicationProxy echoIndicationProxy <- mkEchoIndicationProxy(EchoIndication);
   EchoRequestInternal echoRequestInternal <- mkEchoRequestInternal(echoIndicationProxy.ifc);
   EchoRequestWrapper echoRequestWrapper <- mkEchoRequestWrapper(EchoRequest,echoRequestInternal.ifc);
   
   Swallow swallow <- mkSwallow();
   SwallowWrapper swallowWrapper <- mkSwallowWrapper(Swallow, swallow);
   
   Vector#(3,StdPortal) portals;
   portals[0] = swallowWrapper.portalIfc; 
   portals[1] = echoRequestWrapper.portalIfc; 
   portals[2] = echoIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = nil;
   interface leds = echoRequestInternal.leds;
   interface Empty pins;
   endinterface

endmodule : mkConnectalTop
