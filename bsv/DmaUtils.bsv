// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import BRAM::*;
import FIFO::*;
import Vector::*;
import Gearbox::*;
import FIFOF::*;
import SpecialFIFOs::*;

import BRAMFIFOFLevel::*;
import GetPut::*;
import Dma::*;

function ObjectReadClient#(dataWidth) orc(DmaReadBuffer#(dataWidth,bufferDepth) rb) = rb.dmaClient;
function ObjectWriteClient#(dataWidth) owc(DmaWriteBuffer#(dataWidth,bufferDepth) wb) = wb.dmaClient;
function ObjectReadServer#(dataWidth) ors(DmaReadBuffer#(dataWidth,bufferDepth) rb) = rb.dmaServer;
function ObjectWriteServer#(dataWidth) ows(DmaWriteBuffer#(dataWidth,bufferDepth) wb) = wb.dmaServer;

//
// @brief A buffer for reading from a bus of width dataWidth.
//
// @param dataWidth The number of bits in the bus.
// @param bufferDepth The depth of the internal buffer
//
interface DmaReadBuffer#(numeric type dataWidth, numeric type bufferDepth);
   interface ObjectReadServer #(dataWidth) dmaServer;
   interface ObjectReadClient#(dataWidth) dmaClient;
endinterface

//
// @brief A buffer for writing to a bus of width dataWidth.
//
// @param dataWidth The number of bits in the bus.
// @param bufferDepth The depth of the internal buffer
//
interface DmaWriteBuffer#(numeric type dataWidth, numeric type bufferDepth);
   interface ObjectWriteServer#(dataWidth) dmaServer;
   interface ObjectWriteClient#(dataWidth) dmaClient;
endinterface



//
// @brief Makes a Dma buffer for reading wordSize words from memory.
//
// @param dataWidth The width of the bus in bits.
// @param bufferDepth The depth of the internal buffer
//
module mkDmaReadBuffer(DmaReadBuffer#(dataWidth, bufferDepth))
   provisos(Add#(b__, TAdd#(1,TLog#(bufferDepth)), 8),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift));

   FIFOFLevel#(ObjectData#(dataWidth),bufferDepth)  readBuffer <- mkFIFOFLevel;
   FIFOF#(ObjectRequest)        reqOutstanding <- mkFIFOF();
   Ratchet#(TAdd#(1,TLog#(bufferDepth))) availableBuffers <- mkRatchet(fromInteger(valueOf(bufferDepth)));
   let beat_shift = fromInteger(valueOf(beatShift));
   
   FIFO#(Bool) readyToGet <- mkFIFO();
   rule updateReady;
      readyToGet.enq(unpack(truncate(reqOutstanding.first.burstLen>>beat_shift)) <= availableBuffers.read());
   endrule

   // only issue the readRequest when sufficient buffering is available.  This includes the buffering we have already committed.
   interface ObjectReadServer dmaServer;
      interface Put readReq = toPut(reqOutstanding);
      interface Get readData;
	 method ActionValue#(ObjectData#(dataWidth)) get();
	    availableBuffers.increment(1);
	    let resp <- toGet(readBuffer).get();
	    return resp;
	 endmethod
      endinterface
   endinterface
   interface ObjectReadClient dmaClient;
      interface Get readReq;
	 method ActionValue#(ObjectRequest) get;
	    readyToGet.deq();
	    reqOutstanding.deq;
	    availableBuffers.decrement(unpack(truncate(reqOutstanding.first.burstLen>>beat_shift)));
	    return reqOutstanding.first;
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(ObjectData#(dataWidth) x);
	    readBuffer.fifo.enq(x);
	 endmethod
      endinterface
   endinterface
endmodule

//
// @brief Makes a Dma channel for writing wordSize words from memory.
//
// @param dataWidth The width of the bus in bits.
// @param bufferDepth The depth of the internal buffer
//
module mkDmaWriteBuffer(DmaWriteBuffer#(dataWidth, bufferDepth))
   provisos(Add#(b__, TAdd#(1, TLog#(bufferDepth)), 8),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift));

   FIFOFLevel#(ObjectData#(dataWidth),bufferDepth) writeBuffer <- mkFIFOFLevel;
   FIFOF#(ObjectRequest)        reqOutstanding <- mkFIFOF();
   FIFOF#(Bit#(6))                        doneTags <- mkFIFOF();
   Ratchet#(TAdd#(1,TLog#(bufferDepth))) availableWords <- mkRatchet(fromInteger(valueOf(bufferDepth)));
   let beat_shift = fromInteger(valueOf(beatShift));
   
   FIFO#(Bool) readyToGet <- mkFIFO();
   rule updateReady;
      readyToGet.enq(unpack(truncate(reqOutstanding.first.burstLen>>beat_shift)) <= availableWords.read());
   endrule

   // only issue the writeRequest when sufficient data is available.  This includes the data we have already committed.
   interface ObjectWriteServer dmaServer;
      interface Put writeReq = toPut(reqOutstanding);
      interface Put writeData;
	 method Action put(ObjectData#(dataWidth) d);
	    writeBuffer.fifo.enq(d);
	    availableWords.increment(1);
	 endmethod
      endinterface
      interface Get writeDone = toGet(doneTags);
   endinterface
   interface ObjectWriteClient dmaClient;
      interface Get writeReq;
	 method ActionValue#(ObjectRequest) get;
	    readyToGet.deq();
	    reqOutstanding.deq;
	    availableWords.decrement(unpack(truncate(reqOutstanding.first.burstLen>>beat_shift)));
	    return reqOutstanding.first;
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(ObjectData#(dataWidth)) get();
	    writeBuffer.fifo.deq;
	    return writeBuffer.fifo.first;
	 endmethod
      endinterface
      interface Put writeDone = toPut(doneTags);
   endinterface
endmodule
