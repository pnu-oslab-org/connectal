// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import BRAMFIFO::*;
import FIFO::*;
import FIFOF::*;
import MIMO::*;
import DefaultValue::*;
import SpecialFIFOs::*;
import Vector::*;
import DmaVector::*;
import PortalMemory::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import MemUtils::*;
import FloatingPoint::*;
import Pipe::*;
import FloatOps::*;
import Timer::*;
import RbmTypes::*;
import Assert::*;
import Connectable::*;
import Clocks::*;
import Gearbox::*;
import XilinxCells::*;
import HostInterface::*;
import DotProdServer::*;
import ClientServer::*;
import GetPut::*;

typedef struct {
   a xbase;
   a xlimit;
   a xstep;
   a ybase;
   a ylimit;
   a ystep;
   a zbase;
   a zlimit;
   a zstep;
} XYZRangeConfig#(type a) deriving (Bits, FShow);

interface XYZRangePipeIfc#(type a);
   interface PipeOut#(Tuple2#(a,a)) pipe;
   method Action start(XYZRangeConfig#(a) cfg);
   method Action display();
endinterface

module mkXYZRangePipeOut(XYZRangePipeIfc#(a)) provisos (Arith#(a), Bits#(a,awidth), Eq#(a), Ord#(a));
   Reg#(a) x <- mkReg(0);
   Reg#(a) y <- mkReg(0);
   Reg#(a) z <- mkReg(0);
   Reg#(a) xbase <- mkReg(0);
   Reg#(a) ybase <- mkReg(0);
   Reg#(a) zbase <- mkReg(0);
   Reg#(a) xstep <- mkReg(0);
   Reg#(a) ystep <- mkReg(0);
   Reg#(a) zstep <- mkReg(0);
   Reg#(a) xlimit <- mkReg(0);
   Reg#(a) ylimit <- mkReg(0);
   Reg#(a) zlimit <- mkReg(0);

   interface PipeOut pipe;
      method Tuple2#(a,a) first() if (x < xlimit && y < ylimit);
	 return tuple2(x,y);
      endmethod
      method Action deq if (x < xlimit && y < ylimit);
	 let newx = x;
	 let newy = y+ystep;
	 let newz = z;
	 if (newy >= ylimit && x < xlimit) begin
	    newy = ybase;
	    newx = newx + xstep;
	    if (newx >= xlimit && z < zlimit) begin
	       newx = xbase;
	       newz = z + zstep;
	    end
	 end
	 x <= newx;
	 y <= newy;
      endmethod
      method Bool notEmpty();
	 return (x < xlimit && y < ylimit && z < zlimit);
      endmethod
   endinterface
   method Action start(XYZRangeConfig#(a) cfg) if (x >= xlimit);
      //$display("XYZRangePipe x=%d xlimit=%d xstep=%d y=%d ylimit=%d ystep=%d", cfg.xbase, cfg.xlimit, cfg.xstep, cfg.ybase, cfg.ylimit, cfg.ystep);
      x <= cfg.xbase;
      y <= cfg.ybase;
      xbase <= cfg.xbase;
      ybase <= cfg.ybase;
      zbase <= cfg.zbase;
      xstep <= cfg.xstep;
      ystep <= cfg.ystep;
      zstep <= cfg.zstep;
      xlimit <= cfg.xlimit;
      ylimit <= cfg.ylimit;
      zlimit <= cfg.zlimit;
   endmethod
   method Action display();
      $display("XYZRangePipe x=%d xlimit=%d y=%d ylimit=%d z=%d zlimit=%d xstep=%d ystep=%d zstep=%d", x, xlimit, y, ylimit, z, zlimit,  xstep, ystep, zstep);
   endmethod
endmodule: mkXYZRangePipeOut

module mkColSource#(ObjectReadServer#(TMul#(N,32)) vs, Reg#(UInt#(addrwidth)) numRowsB) (RowColSource#(TMul#(N,32), Vector#(N,MmToken)))
   provisos (Bits#(Vector#(N,Float),asz),
      Div#(asz,8,abytes),
      Log#(abytes,ashift),
      Mul#(abytes, 8, asz)
      );
   
   let cmd_buffer_depth = 32;
   
   let verbose = False;   
   let ashift = valueOf(ashift);
`ifdef TAGGED_TOKENS
   Reg#(UInt#(32)) row <- mkReg(0);
   FIFOF#(UInt#(32)) tagFifo <- mkSizedBRAMFIFOF(cmd_buffer_depth);
`endif
   // perhaps memreadengine could do the labeling
   Reg#(Bit#(ObjectOffsetSize)) countReg <- mkReg(0);
   Reg#(UInt#(addrwidth)) cmdCountReg <- mkReg(0);
   FIFOF#(Bit#(ObjectOffsetSize)) cmdFifo <- mkSizedBRAMFIFOF(cmd_buffer_depth);
   FIFOF#(Vector#(N,Float)) read_data_buffer <- mkFIFOF;
   
   rule read_data;
      let foo <- vs.readData.get;
      read_data_buffer.enq(unpack(foo.data));
   endrule
   
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l, UInt#(32) tag);
`ifdef TAGGED_TOKENS
      tagFifo.enq(tag);
`endif
      if (l != fromInteger(valueOf(TDiv#(K,N)))) begin
	 $display("mkColSource.start error %d %d", l, valueOf(TDiv#(K,N)));
      end
      let cmd = ObjectRequest{pointer:h, offset:a<<ashift, burstLen:fromInteger(valueOf(TDiv#(K,N)))<<ashift, tag:10};
      vs.readReq.put(cmd); //start(h,a,l);
      if(verbose) $display("mkColSource.start %d %d", cmd.offset, cmd.burstLen);
      cmdFifo.enq(l);
   endmethod
   interface PipeOut pipe;
      method Vector#(N,MmToken) first;
	 Vector#(N,MmToken) rv;
	 Vector#(N,Float) foo = read_data_buffer.first;
`ifdef TAGGED_TOKENS
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = MmToken{row:row+fromInteger(i), col:tagFifo.first, v:foo[i], first:False, last:False};
`else
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = MmToken{v:foo[i], first:False, last:False};
`endif
	 if (cmdCountReg == 0)  
	    for(Integer i = 0; i < valueOf(N); i=i+1)
	       rv[i].first = True;

	 if (cmdCountReg+1 == numRowsB)
	    for(Integer i = 0; i < valueOf(N); i=i+1)
	       rv[i].last = True;
	 return rv;
      endmethod
      method Action deq;
	 if(verbose) $display("mkColSource.deq %d %d", countReg+1==cmdFifo.first, cmdCountReg+1==numRowsB);
	 read_data_buffer.deq;
	 if(countReg+1==cmdFifo.first) begin
	    countReg <= 0;
	    cmdFifo.deq;
	    if (cmdCountReg+1 == numRowsB)
	       cmdCountReg <= 0;
	    else
	       cmdCountReg <= cmdCountReg+1;
`ifdef TAGGED_TOKENS
	    tagFifo.deq;
	    row <= 0;
`endif      
	 end
	 else begin
`ifdef TAGGED_TOKENS
	    row <= row+fromInteger(valueOf(N));
`endif
	    countReg <= countReg+1;
	 end
      endmethod
      method Bool notEmpty;
`ifdef TAGGED_TOKENS
	 return (tagFifo.notEmpty && vs.dataPipes[0].notEmpty);
`else
	 return (read_data_buffer.notEmpty);
`endif
      endmethod
   endinterface
endmodule: mkColSource

function Vector#(TMul#(j,k), etype) flattenMatrix(Vector#(j, Vector#(k, etype)) mat);
   function etype flatten(Integer i); return mat[i/valueOf(k)][i%valueOf(k)]; endfunction
   return genWith(flatten);
endfunction

typedef struct {
   ObjectPointer pointer;
   addrtype base;
   addrtype numRows;
   addrtype numColumns;
} MatrixDescriptor#(type addrtype) deriving (Bits);

interface DmaMatrixMultiplyDebug;
   method Bit#(32) macCount();
endinterface
   
// row major layout
interface DmaMatrixMultiplyIfc#(numeric type addrwidth, numeric type dsz);
   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(addrwidth) numRowsA_x_numColumnsA, UInt#(addrwidth) numColumnsA_x_J,
		       UInt#(addrwidth) numRowsA_x_numColumnsB, UInt#(addrwidth) numColumnsB_x_J,
		       UInt#(addrwidth) numRowsA_x_numRowsB,    UInt#(addrwidth) numRowsB_x_J);
   method ActionValue#(Bool) finish();
   interface DmaMatrixMultiplyDebug debug;
endinterface

typedef enum {
   Idle, Ready, Running, Done
   } MMState deriving (Bits, Eq);

/*!
 * Multiplies two matrices A and B and writes the result to memory.
 * Fetches J rows at a time from A and K rows at a time from B.
 * Each cycle, it can fetch N elements of a row or column.
 *
 * Just considering memory bandwidth, every J+K cycles it is ready to perform J*K*N multiply accumulates.
 *
 */
module  mkDmaMatrixMultiply#(Vector#(J, VectorSource#(dsz, Vector#(N, Float))) sA,
			     ObjectReadServer#(TMul#(N,32)) sB,
			     Vector#(J, VectorSink#(dsz, Vector#(N,Float)))    ss,
			     HostType host
			     )(DmaMatrixMultiplyIfc#(addrwidth, dsz))
   provisos (  Mul#(N,n__,K) // K must be an integer multiple of N
	     , Mul#(N,m__,J) // J must be an integer multiple of N
             , Add#(1,o__,J)
	     , Log#(N,nshift)
	     , FShow#(Float)
	     , Arith#(Float)
	     , Bits#(Vector#(N, Float), dsz)
	     , Bits#(MatrixDescriptor#(UInt#(addrwidth)), mdsz)
	     , Bits#(Tuple2#(UInt#(addrwidth), UInt#(addrwidth)), tplsz)
	     , Add#(b__, 20, addrwidth)
	     , Add#(a__, addrwidth, 40)
	     , Add#(c__, addrwidth, 32)
	     , Max#(1, TDiv#(TLog#(J),2), bpc_j)
	     , Max#(1, TDiv#(TLog#(K),2), bpc_k)
      );

   let n = valueOf(N);
   let jj = valueOf(J);
   let kk = valueOf(K);
   let tt = valueOf(T);
   let nshift = valueOf(nshift);
   Bool verbose = False;
   Bool verbose1 = False;
   Bool timing = False;

   let defaultClock <- exposeCurrentClock();
   let defaultReset <- exposeCurrentReset();

   let doubleClock = host.doubleClock;
   let doubleReset = host.doubleReset;

   Reg#(UInt#(32)) cycles <- mkReg(0);
   FIFOF#(MatrixDescriptor#(UInt#(addrwidth))) descFifoA <- mkSizedFIFOF(1);
   FIFOF#(MatrixDescriptor#(UInt#(addrwidth))) descFifoC <- mkSizedFIFOF(1);
   UnFunnelPipe#(1,J,MatrixDescriptor#(UInt#(addrwidth)),bpc_j) descriptorA <- mkPipelinedForkVector(toPipeOut(descFifoA), 0);
   UnFunnelPipe#(1,J,MatrixDescriptor#(UInt#(addrwidth)),bpc_j) descriptorC <- mkPipelinedForkVector(toPipeOut(descFifoC), 2);
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorB <- mkReg(unpack(0));
   Reg#(UInt#(addrwidth)) dotprodCount <- mkReg(0);
   
   Vector#(J, RowColSource#(TMul#(N,32), Vector#(N,MmToken))) sourceA <- mapM(mkRowSource, sA);
   Reg#(UInt#(addrwidth)) numRowsBReg <- mkReg(0);
   RowColSource#(TMul#(N,32), Vector#(N,MmToken)) sourceB <- mkColSource(sB, numRowsBReg);
   Vector#(J, RowColSink#(TMul#(N,32),   Vector#(N,MmToken))) sinks   <- mapM(mkRowColSink,ss);
   Vector#(J, PipeOut#(MmToken))       aPipes <- mapM(mkFunnelGB1(defaultClock, defaultReset, doubleClock, doubleReset), map(getRowColSourcePipe, sourceA));
   PipeOut#(MmToken)       bFunnel <- mkFunnelGB1(defaultClock, defaultReset, doubleClock, doubleReset, sourceB.pipe);
   Vector#(J, PipeOut#(MmToken)) bFunnelPipes <- mkForkVector(bFunnel, clocked_by doubleClock, reset_by doubleReset);

   rule countCycles;
      cycles <= cycles+1;
   endrule

   UInt#(TAdd#(TLog#(K),1)) repetitions = fromInteger(valueOf(K));
   Vector#(J, PipeOut#(MmToken)) aRepeaters <- mapM(mkRepeat(repetitions), aPipes, clocked_by doubleClock, reset_by doubleReset);

   Vector#(T, MmTile) mmTiles <- mapM(mkMmTile(defaultClock, defaultReset), map(fromInteger,genVector), clocked_by doubleClock, reset_by doubleReset);
   Vector#(J, PipeOut#(Vector#(N,MmToken))) fxpipes;
   for (Integer t = 0; t < valueOf(T); t = t+1) begin
      for (Integer i = 0; i < valueof(RowsPerTile); i = i+1) begin
	 let j = t*valueOf(RowsPerTile) + i;
	 mkConnection(toGet(aRepeaters[j]), mmTiles[t].aInputs[i], clocked_by doubleClock, reset_by doubleReset);
	 mkConnection(toGet(bFunnelPipes[j]), mmTiles[t].bInputs[i], clocked_by doubleClock, reset_by doubleReset);
	 fxpipes[j] = mmTiles[t].fxPipes[i];
      end
   end
   
   zipWithM(mkConnection, fxpipes, map(getRowColSinkPipe, sinks));
   
   XYRangePipeIfc#(UInt#(addrwidth)) indexpipeifc <- mkXYRangePipeOut();
   XYRangePipeIfc#(UInt#(addrwidth)) offsetpipeA <- mkXYRangePipeOut();
   XYRangePipeIfc#(UInt#(addrwidth)) offsetpipeC <- mkXYRangePipeOut();
   XYZRangePipeIfc#(UInt#(addrwidth)) offsetpipeB <- mkXYZRangePipeOut();

   Vector#(J, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth)))) indexpipes <- mkForkVector(indexpipeifc.pipe);
   Vector#(J, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth)))) offsetpipesA <- mkForkVector(offsetpipeA.pipe);
   Vector#(J, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth)))) offsetpipesC <- mkForkVector(offsetpipeC.pipe);
   
   Vector#(J, Reg#(UInt#(32))) lastStartAs <- replicateM(mkReg(0));
   Reg#(UInt#(32)) lastStartB <- mkReg(0);
   Vector#(K, Reg#(UInt#(32))) lastStartCs <- replicateM(mkReg(0));
      
   Reg#(Bool) running <- mkReg(False);
   FIFOF#(Bool) doneFifo <- mkFIFOF();
   
   Vector#(J, Reg#(UInt#(addrwidth))) startAOffset <- replicateM(mkReg(0));
   Vector#(J, Reg#(UInt#(addrwidth))) startCOffset <- replicateM(mkReg(0));
   
   
   rule startSourceB;
      match { .startBBase, .startBOffset } <- toGet(offsetpipeB.pipe).get();
      let startB = startBBase + startBOffset;
      lastStartB <= cycles;
      let interval = cycles-lastStartB;
      if (timing || verbose) $display($format(fshow(interval)+fshow(" startB=")+fshow(startB)));
      sourceB.start(descriptorB.pointer, pack(extend(startB>>nshift)), fromInteger(kk)>>nshift, 0);
   endrule
   
   //
   /////////////////////////////////////////////////
   
   Vector#(J, FIFO#(void)) controlDependenceA <- replicateM(mkFIFO);   
   for (Integer j = 0; j < jj; j = j + 1) begin

      int jint = fromInteger(j);
      rule startSourceAndSink;
	 
	 if(j > 0)
	    controlDependenceA[j-1].deq;
	 if(j < jj-1)
	    controlDependenceA[j].enq(?);

	 Tuple2#(UInt#(addrwidth),UInt#(addrwidth)) index <- toGet(indexpipes[j]).get();
	 
	 let row = tpl_1(index)+fromInteger(j);
	 let col = tpl_2(index);
	 
	 match { .startABase, .unusedA } <- toGet(offsetpipesA[j]).get();
	 match { .startCBase, .offsetC } <- toGet(offsetpipesC[j]).get();
	 let startA = startABase + startAOffset[j];
	 let startC = startCBase + startCOffset[j] + offsetC;
	 
	 int jint = fromInteger(j);
	 if (timing || verbose) $display($format(fshow(cycles)+fshow("    start A index=")+fshow(tuple2(row,col))
						 +fshow(" startA=")+fshow(startA)
						 +fshow(" startC=")+fshow(startC)
						 +fshow(" j=")+fshow(jint)));
	 
	 sourceA[j].start(descriptorA[j].first.pointer, pack(extend(startA>>nshift)), pack(extend(descriptorA[j].first.numColumns>>nshift)), extend(row));
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceA[")+fshow(jint)+fshow("].start")+fshow(startA)));
	 sinks[j].start(descriptorC[j].first.pointer, pack(extend(startC>>nshift)), fromInteger(kk/n));
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("      sinks[")+fshow(jint)+fshow("].start")+fshow(startC)));
	 
      endrule

      rule finishSourceA;
	 if (timing || verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceA[")+fshow(jint)+fshow("].finish ")));
	 let b <- sourceA[j].finish();
      endrule

      rule finishSink;
	 $dumpoff();
	 // each time we write a burst of k values via sinks
	 //let index <- toGet(indexpipes[jj+kk+1]).get();
	 let b <- sinks[j].finish();
	 let c = dotprodCount-fromInteger(kk);
	 int jint = fromInteger(j);
	 if (timing || verbose1) $display($format(fshow(cycles)+fshow("    finishSink c")+fshow(c)+fshow(" j=")+fshow(jint)));
	 dotprodCount <= c;
	 if (c == 0) begin
	    running <= False;
	    doneFifo.enq(?);
	    for(Integer i = 0; i < jj; i=i+1) begin
	       descriptorA[i].deq;
	       descriptorC[i].deq;
	    end
	 end
      endrule
   end

   FIFO#(Bool) initNumEltsFifo <- mkFIFO();
   rule dotProdsNumElts;
      initNumEltsFifo.deq();
      let numColumnsA = descriptorA[0].first.numColumns;
      let numColumnsB = descriptorB.numColumns;
      for (Integer j = 0; j < jj; j = j + 1) begin
	 startAOffset[j] <= fromInteger(j)*numColumnsA;
	 startCOffset[j] <= fromInteger(j)*numColumnsB;
      end
  endrule

   function Bit#(32) my_add(Tuple2#(Bit#(32),Bit#(32)) ab); match { .a, .b } = ab; return a+b; endfunction
   function PipeOut#(Bit#(32)) mmTileMacCount(MmTile mmtile); return mmtile.debug.macCount; endfunction
   Vector#(T, PipeOut#(Vector#(2,Bit#(32)))) macCountPipes <- mapM(mkUnfunnelGB(defaultClock, defaultReset, doubleClock, doubleReset),
								   map(mapPipe(replicate),
								       map(mmTileMacCount, mmTiles)));
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(my_add, map(mapPipe(head),macCountPipes));
   Reg#(Bit#(32)) macCountReg <- mkReg(0);
   rule updateMacCount;
      let mc <- toGet(macCountPipe).get();
      macCountReg <= mc;
   endrule

   function Bool pipeNotEmpty(RowColSource#(asz, a) vs); return vs.pipe.notEmpty(); endfunction

   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(addrwidth) numRowsA_x_numColumnsA, UInt#(addrwidth) numColumnsA_x_J,
		       UInt#(addrwidth) numRowsA_x_numColumnsB /*mdk*/, 
		       UInt#(addrwidth) numColumnsB_x_J /*mdk*/,
		       UInt#(addrwidth) numRowsA_x_numRowsB,    
		       UInt#(addrwidth) numRowsB_x_numColumnsB /*mdk*/
		       ) if (!running);
      XYRangeConfig#(UInt#(addrwidth)) indexcfg  = XYRangeConfig {xbase: 0, xlimit: numRowsA, xstep: fromInteger(jj),
								  ybase: 0, ylimit: numColumnsB, ystep: fromInteger(kk) };
      XYRangeConfig#(UInt#(addrwidth)) offsetcfgA = XYRangeConfig {xbase: 0, xlimit: numRowsA_x_numColumnsA, xstep: numColumnsA_x_J,
								  ybase: 0, ylimit: numColumnsB, ystep: fromInteger(kk) };
      XYZRangeConfig#(UInt#(addrwidth)) offsetcfgB = XYZRangeConfig {xbase: 0, xlimit: numColumnsB, xstep: fromInteger(kk),
								     ybase: 0, ylimit: numRowsB_x_numColumnsB, ystep: numColumnsB,
								     zbase: 0, zlimit: numRowsA, zstep: fromInteger(jj)};
      XYRangeConfig#(UInt#(addrwidth)) offsetcfgC = XYRangeConfig {xbase: 0, xlimit: numRowsA_x_numColumnsB, xstep: numColumnsB_x_J,
								  ybase: 0, ylimit: numColumnsB, ystep: fromInteger(kk) };
      descFifoA.enq(MatrixDescriptor { pointer: pointerA, base: 0, numRows: numRowsA, numColumns: numColumnsA});
      descriptorB <= MatrixDescriptor { pointer: pointerB, base: 0, numRows: numRowsB, numColumns: numColumnsB};
      descFifoC.enq(MatrixDescriptor { pointer: pointerC, base: 0, numRows: numRowsA, numColumns: numRowsB});
      dotprodCount <= numRowsA_x_numColumnsB;
      numRowsBReg <= numRowsB;
      running <= True;

      if (verbose) $display("mm pointerA=%d pointerB=%d pointerC=%d\n", pointerA, pointerB, pointerC);
      if (verbose) $display("mm.start ra=%d ca=%d rb=%d cb=%d dotprodCount=%d", numRowsA, numColumnsA, numRowsB, numColumnsB, dotprodCount);
      if (verbose) $display($format(fshow("mm.start ")+fshow(indexcfg)));
      if (verbose) $display($format(fshow("offsetcfgA ")+fshow(offsetcfgA)));
      if (verbose) $display($format(fshow("offsetcfgB ")+fshow(offsetcfgB)));
      if (verbose) $display($format(fshow("offsetcfgC ")+fshow(offsetcfgC)));
      indexpipeifc.start(indexcfg);
      offsetpipeA.start(offsetcfgA);
      offsetpipeC.start(offsetcfgC);
      offsetpipeB.start(offsetcfgB);
      
      $display("initNumElts");
      initNumEltsFifo.enq(True);

      //$dumpfile("test.vcd");
      //$dumpvars();
   endmethod
   method ActionValue#(Bool) finish();
      if (verbose) $display("mm.finish()");
      doneFifo.deq();
      return True;
   endmethod
   interface DmaMatrixMultiplyDebug debug;
      method Bit#(32) macCount(); return macCountReg; endmethod
    endinterface
endmodule : mkDmaMatrixMultiply

interface DramMatrixMultiply#(numeric type n, numeric type dmasz, numeric type nm);
   interface Vector#(nm, ObjectReadClient#(dmasz)) readClients;
   interface Vector#(nm, ObjectWriteClient#(dmasz)) writeClients;
   method Action start(ObjectPointer pointerA, UInt#(MMSize) numRowsA, UInt#(MMSize) numColumnsA,
		       ObjectPointer pointerB, UInt#(MMSize) numRowsB, UInt#(MMSize) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(MMSize) numRowsA_x_numColumnsA, UInt#(MMSize) numColumnsA_x_J,
		       UInt#(MMSize) numRowsA_x_numColumnsB, UInt#(MMSize) numColumnsB_x_J,
		       UInt#(MMSize) numRowsA_x_numRowsB,    UInt#(MMSize) numRowsB_x_J);
   method ActionValue#(Bool) finish();
   interface DmaMatrixMultiplyDebug debug;
endinterface
      
module  mkDramMatrixMultiply#(HostType host)(DramMatrixMultiply#(N,TMul#(N,32),2));

   MemwriteEngineV#(TMul#(N,32),2, J)   writeEngine <- mkMemwriteEngine();
   StaticSched#(J)                     rowReadSched <- mkRoundRobin;
   MemreadEngineV#(TMul#(N,32), 2, J) rowReadEngine <- mkMemreadEngineStaticSched(rowReadSched);
   MemReader#(TMul#(N,32))                colReader <- mkMemReader;
   MemWriter#(TMul#(32,N)) bogusWriter <- mkMemWriter;
   
   Vector#(J, Server#(MemengineCmd,Bool)) rowReadServers = rowReadEngine.readServers;
   Vector#(J, PipeOut#(Bit#(TMul#(N,32)))) rowReadDataPipes = rowReadEngine.dataPipes;
   Vector#(J, VectorSource#(DmaSz, Vector#(N,Float))) xvfsources <- mapM(uncurry(mkMemreadVectorSource), zip(rowReadServers, rowReadDataPipes));
   Vector#(J,   VectorSink#(DmaSz, Vector#(N,Float)))      sinks <- mapM(uncurry(mkMemwriteVectorSink),   zip(writeEngine.writeServers,   writeEngine.dataPipes));
   
   DmaMatrixMultiplyIfc#(MMSize,DmaSz) dmaMMF <- mkDmaMatrixMultiply(xvfsources, colReader.readServer, sinks, host);
   interface Vector readClients  = cons(rowReadEngine.dmaClient, cons(colReader.readClient, nil));
   interface Vector writeClients = cons(writeEngine.dmaClient,   cons(bogusWriter.writeClient, nil));
   method start = dmaMMF.start;
   method finish = dmaMMF.finish;
   interface DmaMatrixMultiplyDebug debug = dmaMMF.debug;
endmodule
   
interface Mm#(numeric type n);
   interface MmRequest mmRequest;
   interface MmDebugRequest mmDebug;
   interface TimerRequest timerRequest;
   interface Vector#(NumberOfMasters, ObjectReadClient#(TMul#(32,n)))  readClients;
   interface Vector#(NumberOfMasters, ObjectWriteClient#(TMul#(32,n))) writeClients;
endinterface

module  mkMm#(MmIndication ind, TimerIndication timerInd, MmDebugIndication mmDebugIndication, HostType host)(Mm#(N))
   provisos (Add#(1,a__,N),
	     Add#(N,0,n),
	     Mul#(N,32,DmaSz)
	     );

   let n = valueOf(n);

   DramMatrixMultiply#(N, TMul#(N,32),NumberOfMasters) dmaMMF <- mkDramMatrixMultiply(host);

   Reg#(Bit#(64)) mmfCycles <- mkReg(0);
   rule countMmfCycles;
      mmfCycles <= mmfCycles + 1;
   endrule

   FIFOF#(Bool) busyFifo <- mkFIFOF();
   rule mmfDone;
      let d <- dmaMMF.finish();
      busyFifo.deq();
      ind.mmfDone(mmfCycles);
   endrule

   FIFOF#(Bool) timerRunning <- mkFIFOF();
   Reg#(Bit#(64)) cycleCount <- mkReg(0);
   Reg#(Bit#(64)) idleCount <- mkReg(0);
   rule countCycles if (timerRunning.notEmpty());
      cycleCount <= cycleCount + 1;
      if (!busyFifo.notEmpty())
	 idleCount <= idleCount + 1;
   endrule

   interface TimerRequest timerRequest;
      method Action startTimer() if (!timerRunning.notEmpty());
	 cycleCount <= 0;
	 idleCount <= 0;
	 timerRunning.enq(True);
      endmethod
      method Action stopTimer();
	 timerRunning.deq();
	 timerInd.elapsedCycles(cycleCount, idleCount);
      endmethod
   endinterface

   interface MmRequest mmRequest;
      method Action mmf(Bit#(32) h1, Bit#(32) r1, Bit#(32) c1,
			Bit#(32) h2, Bit#(32) r2, Bit#(32) c2,
			Bit#(32) h3,
			Bit#(32) r1_x_c1, Bit#(32) c1_x_j,
			Bit#(32) r1_x_c2, Bit#(32) c2_x_j,
			Bit#(32) r1_x_r2, Bit#(32) r2_x_c2);
	 dmaMMF.start(h1, unpack(truncate(r1)), unpack(truncate(c1)),
		      h2, unpack(truncate(r2)), unpack(truncate(c2)),
		      h3,
		      unpack(truncate(r1_x_c1)), unpack(truncate(c1_x_j)),
		      unpack(truncate(r1_x_c2)), unpack(truncate(c2_x_j)),
		      unpack(truncate(r1_x_r2)), unpack(truncate(r2_x_c2)));

	 mmfCycles <= 0;
	 busyFifo.enq(True);
      endmethod
   endinterface
   interface MmDebugRequest mmDebug;
      method Action debug();
	 let macCount = dmaMMF.debug.macCount();
	 mmDebugIndication.debug(macCount);
      endmethod
   endinterface

   interface Vector readClients = dmaMMF.readClients;
   interface Vector writeClients =  dmaMMF.writeClients;

endmodule

