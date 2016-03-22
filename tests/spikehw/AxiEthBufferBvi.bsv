
/*
   ../../generated/scripts/importbvi.py
   -o
   AxiEthBufferBvi.bsv
   -I
   AxiEthBuffer
   -P
   AxiEthBuffer
   -c
   S_AXI_ACLK
   -r
   S_AXI_ARESETN
   -c
   AXI_STR_TXD_ACLK
   -r
   AXI_STR_TXD_ARESETN
   -c
   AXI_STR_TXC_ACLK
   -r
   AXI_STR_TXC_ARESETN
   -c
   AXI_STR_RXD_ACLK
   -r
   AXI_STR_RXD_ARESETN
   -c
   AXI_STR_RXS_ACLK
   -r
   AXI_STR_RXS_ARESETN
   -c
   rx_mac_aclk
   -r
   rx_reset
   -c
   tx_mac_aclk
   -r
   tx_reset
   -r
   PHY_RST_N
   -r
   RESET2PCSPMA
   -r
   RESET2TEMACn
   -c
   GTX_CLK
   -n
   speed_is_10_100
   -f
   S_AXI_2TEMAC
   -n
   RESET2PCSPMA
   -n
   RESET2TEMACn
   cores/nfsume/eth_buf/eth_buf_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

interface AxiEthBufferClocks;
   interface Clock axi_str_rxd_aclk;
   interface Clock axi_str_rxs_aclk;
   interface Clock axi_str_txc_aclk;
   interface Clock axi_str_txd_aclk;
   interface Clock gtx_clk;
   interface Clock rx_mac_aclk;
   interface Clock s_axi_aclk;
   interface Clock tx_mac_aclk;
   interface Reset axi_str_rxd_aresetn;
   interface Reset axi_str_rxs_aresetn;
   interface Reset axi_str_txc_aresetn;
   interface Reset axi_str_txd_aresetn;
   interface Reset rx_reset;
   interface Reset s_axi_aresetn;
   interface Reset tx_reset;
endinterface

(* always_ready, always_enabled *)
interface AxiethbufferAxi;
    method Bit#(32)     str_rxd_data();
    method Bit#(4)     str_rxd_keep();
    method Bit#(1)     str_rxd_last();
    method Action      str_rxd_ready(Bit#(1) v);
    method Bit#(1)     str_rxd_valid();
    method Bit#(32)     str_rxs_data();
    method Bit#(4)     str_rxs_keep();
    method Bit#(1)     str_rxs_last();
    method Action      str_rxs_ready(Bit#(1) v);
    method Bit#(1)     str_rxs_valid();
    method Action      str_txc_tdata(Bit#(32) v);
    method Action      str_txc_tkeep(Bit#(4) v);
    method Action      str_txc_tlast(Bit#(1) v);
    method Bit#(1)     str_txc_tready();
    method Action      str_txc_tvalid(Bit#(1) v);
    method Action      str_txd_tdata(Bit#(32) v);
    method Action      str_txd_tkeep(Bit#(4) v);
    method Action      str_txd_tlast(Bit#(1) v);
    method Bit#(1)     str_txd_tready();
    method Action      str_txd_tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferEmac;
    method Action      client_autoneg_int(Bit#(1) v);
    method Action      reset_done_int(Bit#(1) v);
    method Action      rx_dcm_locked_int(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface AxiethbufferMdc;
    method Action      temac(Bit#(1) v);
    method Bit#(1)     top();
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferMdio;
    method Bit#(1)     i_temac();
    method Action      i_top(Bit#(1) v);
    method Action      o_pcspma(Bit#(1) v);
    method Action      o_temac(Bit#(1) v);
    method Bit#(1)     o_top();
    method Action      t_pcspma(Bit#(1) v);
    method Action      t_temac(Bit#(1) v);
    method Bit#(1)     t_top();
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferPause;
    method Bit#(1)     req();
    method Bit#(17)     val();
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferPcspma;
    method Action      status_vector(Bit#(16) v);
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferPhy;
    method Reset     rst_n();
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferRx;
    method Action      axis_mac_tdata(Bit#(8) v);
    method Action      axis_mac_tlast(Bit#(1) v);
    method Action      axis_mac_tuser(Bit#(1) v);
    method Action      axis_mac_tvalid(Bit#(1) v);
    method Action      clk_enable_in(Bit#(1) v);
    method Action      statistics_valid(Bit#(1) v);
    method Action      statistics_vector(Bit#(28) v);
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferS_axi;
    method Action      araddr(Bit#(18) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(18) v);
    method Bit#(1)     awready();
    method Action      awvalid(Bit#(1) v);
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(32)     rdata();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(32) v);
    method Bit#(1)     wready();
    method Action      wstrb(Bit#(4) v);
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferS_axi_2temac;
    method Bit#(12)     araddr();
    method Action      arready(Bit#(1) v);
    method Bit#(1)     arvalid();
    method Bit#(12)     awaddr();
    method Action      awready(Bit#(1) v);
    method Bit#(1)     awvalid();
    method Bit#(1)     bready();
    method Action      bresp(Bit#(2) v);
    method Action      bvalid(Bit#(1) v);
    method Action      rdata(Bit#(32) v);
    method Bit#(1)     rready();
    method Action      rresp(Bit#(2) v);
    method Action      rvalid(Bit#(1) v);
    method Bit#(32)     wdata();
    method Action      wready(Bit#(1) v);
    method Bit#(1)     wvalid();
endinterface
(* always_ready, always_enabled *)
interface AxiethbufferTx;
    method Bit#(8)     axis_mac_tdata();
    method Bit#(1)     axis_mac_tlast();
    method Action      axis_mac_tready(Bit#(1) v);
    method Bit#(1)     axis_mac_tuser();
    method Bit#(1)     axis_mac_tvalid();
    method Bit#(9)     ifg_delay();
endinterface
(* always_ready, always_enabled *)
interface AxiEthBuffer;
    interface AxiethbufferAxi     axi;
    interface AxiethbufferEmac     emac;
    method Bit#(1)     interrupt();
    interface AxiethbufferMdc     mdc;
    interface AxiethbufferMdio     mdio;
    interface AxiethbufferPause     pause;
    interface AxiethbufferPcspma     pcspma;
    interface AxiethbufferPhy     phy;
    method Reset     reset2pcspma();
    method Reset     reset2temacn();
    interface AxiethbufferRx     rx;
    interface AxiethbufferS_axi_2temac     s_axi_2temac;
    interface AxiethbufferS_axi     s_axi;
    method Action      speed_is_10_100(Bit#(1) v);
    interface AxiethbufferTx     tx;
endinterface
import "BVI" eth_buf =
module mkAxiEthBuffer#(AxiEthBufferClocks clks)(AxiEthBuffer);
    default_clock clk();
    default_reset rst();
    input_clock axi_str_rxd_aclk(AXI_STR_RXD_ACLK) = clks.axi_str_rxd_aclk;
    input_reset axi_str_rxd_aresetn(AXI_STR_RXD_ARESETN) = clks.axi_str_rxd_aresetn;
    input_clock axi_str_rxs_aclk(AXI_STR_RXS_ACLK) = clks.axi_str_rxs_aclk;
    input_reset axi_str_rxs_aresetn(AXI_STR_RXS_ARESETN) = clks.axi_str_rxs_aresetn;
    input_clock axi_str_txc_aclk(AXI_STR_TXC_ACLK) = clks.axi_str_txc_aclk;
    input_reset axi_str_txc_aresetn(AXI_STR_TXC_ARESETN) = clks.axi_str_txc_aresetn;
    input_clock axi_str_txd_aclk(AXI_STR_TXD_ACLK) = clks.axi_str_txd_aclk;
    input_reset axi_str_txd_aresetn(AXI_STR_TXD_ARESETN) = clks.axi_str_txd_aresetn;
    input_clock gtx_clk(GTX_CLK) = clks.gtx_clk;
    input_clock rx_mac_aclk(rx_mac_aclk) = clks.rx_mac_aclk;
    input_reset rx_reset(rx_reset) = clks.rx_reset;
    input_clock s_axi_aclk(S_AXI_ACLK) = clks.s_axi_aclk;
    input_reset s_axi_aresetn(S_AXI_ARESETN) = clks.s_axi_aresetn;
    input_clock tx_mac_aclk(tx_mac_aclk) = clks.tx_mac_aclk;
    input_reset tx_reset(tx_reset) = clks.tx_reset;
    interface AxiethbufferAxi     axi;
        method AXI_STR_RXD_DATA str_rxd_data() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method AXI_STR_RXD_KEEP str_rxd_keep() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method AXI_STR_RXD_LAST str_rxd_last() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method str_rxd_ready(AXI_STR_RXD_READY) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_RXD_READY);
        method AXI_STR_RXD_VALID str_rxd_valid() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method AXI_STR_RXS_DATA str_rxs_data() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method AXI_STR_RXS_KEEP str_rxs_keep() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method AXI_STR_RXS_LAST str_rxs_last() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method str_rxs_ready(AXI_STR_RXS_READY) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_RXS_READY);
        method AXI_STR_RXS_VALID str_rxs_valid() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method str_txc_tdata(AXI_STR_TXC_TDATA) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_TXC_TDATA);
        method str_txc_tkeep(AXI_STR_TXC_TKEEP) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_TXC_TKEEP);
        method str_txc_tlast(AXI_STR_TXC_TLAST) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_TXC_TLAST);
        method AXI_STR_TXC_TREADY str_txc_tready() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method str_txc_tvalid(AXI_STR_TXC_TVALID) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_TXC_TVALID);
        method str_txd_tdata(AXI_STR_TXD_TDATA) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_TXD_TDATA);
        method str_txd_tkeep(AXI_STR_TXD_TKEEP) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_TXD_TKEEP);
        method str_txd_tlast(AXI_STR_TXD_TLAST) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_TXD_TLAST);
        method AXI_STR_TXD_TREADY str_txd_tready() clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn);
        method str_txd_tvalid(AXI_STR_TXD_TVALID) clocked_by (axi_str_txd_aclk) reset_by (axi_str_txd_aresetn) enable((*inhigh*) EN_AXI_STR_TXD_TVALID);
    endinterface
    interface AxiethbufferEmac     emac;
        method client_autoneg_int(EMAC_CLIENT_AUTONEG_INT) enable((*inhigh*) EN_EMAC_CLIENT_AUTONEG_INT);
        method reset_done_int(EMAC_RESET_DONE_INT) enable((*inhigh*) EN_EMAC_RESET_DONE_INT);
        method rx_dcm_locked_int(EMAC_RX_DCM_LOCKED_INT) enable((*inhigh*) EN_EMAC_RX_DCM_LOCKED_INT);
    endinterface
    method INTERRUPT interrupt();
    interface AxiethbufferMdc     mdc;
        method temac(mdc_temac) enable((*inhigh*) EN_mdc_temac);
        method mdc_top top();
    endinterface
    interface AxiethbufferMdio     mdio;
        method mdio_i_temac i_temac();
        method i_top(mdio_i_top) enable((*inhigh*) EN_mdio_i_top);
        method o_pcspma(mdio_o_pcspma) enable((*inhigh*) EN_mdio_o_pcspma);
        method o_temac(mdio_o_temac) enable((*inhigh*) EN_mdio_o_temac);
        method mdio_o_top o_top();
        method t_pcspma(mdio_t_pcspma) enable((*inhigh*) EN_mdio_t_pcspma);
        method t_temac(mdio_t_temac) enable((*inhigh*) EN_mdio_t_temac);
        method mdio_t_top t_top();
    endinterface
    interface AxiethbufferPause     pause;
        method pause_req req();
        method pause_val val();
    endinterface
    interface AxiethbufferPcspma     pcspma;
        method status_vector(PCSPMA_STATUS_VECTOR) enable((*inhigh*) EN_PCSPMA_STATUS_VECTOR);
    endinterface
    interface AxiethbufferPhy     phy;
        output_reset rst_n(PHY_RST_N);
    endinterface
    output_reset reset2pcspma(RESET2PCSPMA);
    output_reset reset2temacn(RESET2TEMACn);
    interface AxiethbufferRx     rx;
        method axis_mac_tdata(rx_axis_mac_tdata) clocked_by (rx_mac_aclk) reset_by (rx_reset) enable((*inhigh*) EN_rx_axis_mac_tdata);
        method axis_mac_tlast(rx_axis_mac_tlast) clocked_by (rx_mac_aclk) reset_by (rx_reset) enable((*inhigh*) EN_rx_axis_mac_tlast);
        method axis_mac_tuser(rx_axis_mac_tuser) clocked_by (rx_mac_aclk) reset_by (rx_reset) enable((*inhigh*) EN_rx_axis_mac_tuser);
        method axis_mac_tvalid(rx_axis_mac_tvalid) clocked_by (rx_mac_aclk) reset_by (rx_reset) enable((*inhigh*) EN_rx_axis_mac_tvalid);
        method clk_enable_in(rx_CLK_ENABLE_IN) clocked_by (rx_mac_aclk) reset_by (rx_reset) enable((*inhigh*) EN_rx_CLK_ENABLE_IN);
        method statistics_valid(rx_statistics_valid) clocked_by (rx_mac_aclk) reset_by (rx_reset) enable((*inhigh*) EN_rx_statistics_valid);
        method statistics_vector(rx_statistics_vector) clocked_by (rx_mac_aclk) reset_by (rx_reset) enable((*inhigh*) EN_rx_statistics_vector);
    endinterface
    interface AxiethbufferS_axi_2temac     s_axi_2temac;
        method S_AXI_2TEMAC_ARADDR araddr();
        method arready(S_AXI_2TEMAC_ARREADY) enable((*inhigh*) EN_S_AXI_2TEMAC_ARREADY);
        method S_AXI_2TEMAC_ARVALID arvalid();
        method S_AXI_2TEMAC_AWADDR awaddr();
        method awready(S_AXI_2TEMAC_AWREADY) enable((*inhigh*) EN_S_AXI_2TEMAC_AWREADY);
        method S_AXI_2TEMAC_AWVALID awvalid();
        method S_AXI_2TEMAC_BREADY bready();
        method bresp(S_AXI_2TEMAC_BRESP) enable((*inhigh*) EN_S_AXI_2TEMAC_BRESP);
        method bvalid(S_AXI_2TEMAC_BVALID) enable((*inhigh*) EN_S_AXI_2TEMAC_BVALID);
        method rdata(S_AXI_2TEMAC_RDATA) enable((*inhigh*) EN_S_AXI_2TEMAC_RDATA);
        method S_AXI_2TEMAC_RREADY rready();
        method rresp(S_AXI_2TEMAC_RRESP) enable((*inhigh*) EN_S_AXI_2TEMAC_RRESP);
        method rvalid(S_AXI_2TEMAC_RVALID) enable((*inhigh*) EN_S_AXI_2TEMAC_RVALID);
        method S_AXI_2TEMAC_WDATA wdata();
        method wready(S_AXI_2TEMAC_WREADY) enable((*inhigh*) EN_S_AXI_2TEMAC_WREADY);
        method S_AXI_2TEMAC_WVALID wvalid();
    endinterface
    interface AxiethbufferS_axi     s_axi;
        method araddr(S_AXI_ARADDR) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_ARADDR);
        method S_AXI_ARREADY arready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method arvalid(S_AXI_ARVALID) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_ARVALID);
        method awaddr(S_AXI_AWADDR) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_AWADDR);
        method S_AXI_AWREADY awready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method awvalid(S_AXI_AWVALID) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_AWVALID);
        method bready(S_AXI_BREADY) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_BREADY);
        method S_AXI_BRESP bresp() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method S_AXI_BVALID bvalid() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method S_AXI_RDATA rdata() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method rready(S_AXI_RREADY) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_RREADY);
        method S_AXI_RRESP rresp() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method S_AXI_RVALID rvalid() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method wdata(S_AXI_WDATA) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_WDATA);
        method S_AXI_WREADY wready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method wstrb(S_AXI_WSTRB) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_WSTRB);
        method wvalid(S_AXI_WVALID) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_S_AXI_WVALID);
    endinterface
    method speed_is_10_100(speed_is_10_100) enable((*inhigh*) EN_speed_is_10_100);
    interface AxiethbufferTx     tx;
        method tx_axis_mac_tdata axis_mac_tdata() clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tx_axis_mac_tlast axis_mac_tlast() clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method axis_mac_tready(tx_axis_mac_tready) clocked_by (tx_mac_aclk) reset_by (tx_reset) enable((*inhigh*) EN_tx_axis_mac_tready);
        method tx_axis_mac_tuser axis_mac_tuser() clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tx_axis_mac_tvalid axis_mac_tvalid() clocked_by (tx_mac_aclk) reset_by (tx_reset);
        method tx_ifg_delay ifg_delay() clocked_by (tx_mac_aclk) reset_by (tx_reset);
    endinterface
    schedule (axi.str_rxd_data, axi.str_rxd_keep, axi.str_rxd_last, axi.str_rxd_ready, axi.str_rxd_valid, axi.str_rxs_data, axi.str_rxs_keep, axi.str_rxs_last, axi.str_rxs_ready, axi.str_rxs_valid, axi.str_txc_tdata, axi.str_txc_tkeep, axi.str_txc_tlast, axi.str_txc_tready, axi.str_txc_tvalid, axi.str_txd_tdata, axi.str_txd_tkeep, axi.str_txd_tlast, axi.str_txd_tready, axi.str_txd_tvalid, emac.client_autoneg_int, emac.reset_done_int, emac.rx_dcm_locked_int, interrupt, mdc.temac, mdc.top, mdio.i_temac, mdio.i_top, mdio.o_pcspma, mdio.o_temac, mdio.o_top, mdio.t_pcspma, mdio.t_temac, mdio.t_top, pause.req, pause.val, pcspma.status_vector, rx.axis_mac_tdata, rx.axis_mac_tlast, rx.axis_mac_tuser, rx.axis_mac_tvalid, rx.clk_enable_in, rx.statistics_valid, rx.statistics_vector, s_axi_2temac.araddr, s_axi_2temac.arready, s_axi_2temac.arvalid, s_axi_2temac.awaddr, s_axi_2temac.awready, s_axi_2temac.awvalid, s_axi_2temac.bready, s_axi_2temac.bresp, s_axi_2temac.bvalid, s_axi_2temac.rdata, s_axi_2temac.rready, s_axi_2temac.rresp, s_axi_2temac.rvalid, s_axi_2temac.wdata, s_axi_2temac.wready, s_axi_2temac.wvalid, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wstrb, s_axi.wvalid, speed_is_10_100, tx.axis_mac_tdata, tx.axis_mac_tlast, tx.axis_mac_tready, tx.axis_mac_tuser, tx.axis_mac_tvalid, tx.ifg_delay) CF (axi.str_rxd_data, axi.str_rxd_keep, axi.str_rxd_last, axi.str_rxd_ready, axi.str_rxd_valid, axi.str_rxs_data, axi.str_rxs_keep, axi.str_rxs_last, axi.str_rxs_ready, axi.str_rxs_valid, axi.str_txc_tdata, axi.str_txc_tkeep, axi.str_txc_tlast, axi.str_txc_tready, axi.str_txc_tvalid, axi.str_txd_tdata, axi.str_txd_tkeep, axi.str_txd_tlast, axi.str_txd_tready, axi.str_txd_tvalid, emac.client_autoneg_int, emac.reset_done_int, emac.rx_dcm_locked_int, interrupt, mdc.temac, mdc.top, mdio.i_temac, mdio.i_top, mdio.o_pcspma, mdio.o_temac, mdio.o_top, mdio.t_pcspma, mdio.t_temac, mdio.t_top, pause.req, pause.val, pcspma.status_vector, rx.axis_mac_tdata, rx.axis_mac_tlast, rx.axis_mac_tuser, rx.axis_mac_tvalid, rx.clk_enable_in, rx.statistics_valid, rx.statistics_vector, s_axi_2temac.araddr, s_axi_2temac.arready, s_axi_2temac.arvalid, s_axi_2temac.awaddr, s_axi_2temac.awready, s_axi_2temac.awvalid, s_axi_2temac.bready, s_axi_2temac.bresp, s_axi_2temac.bvalid, s_axi_2temac.rdata, s_axi_2temac.rready, s_axi_2temac.rresp, s_axi_2temac.rvalid, s_axi_2temac.wdata, s_axi_2temac.wready, s_axi_2temac.wvalid, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wstrb, s_axi.wvalid, speed_is_10_100, tx.axis_mac_tdata, tx.axis_mac_tlast, tx.axis_mac_tready, tx.axis_mac_tuser, tx.axis_mac_tvalid, tx.ifg_delay);
endmodule
