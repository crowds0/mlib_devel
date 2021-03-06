--  Copyright (c) 2005-2006, Regents of the University of California
--  All rights reserved.
--
--  Redistribution and use in source and binary forms, with or without modification,
--  are permitted provided that the following conditions are met:
--
--      - Redistributions of source code must retain the above copyright notice,
--          this list of conditions and the following disclaimer.
--      - Redistributions in binary form must reproduce the above copyright
--          notice, this list of conditions and the following disclaimer
--          in the documentation and/or other materials provided with the
--          distribution.
--      - Neither the name of the University of California, Berkeley nor the
--          names of its contributors may be used to endorse or promote
--          products derived from this software without specific prior
--          written permission.
--
--  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
--  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
--  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

--   #      ###    #####          #######
--  ##     #   #  #     #  #      #
-- # #    # #   # #        #      #
--   #    #  #  # #  ####  #####  #####
--   #    #   # # #     #  #    # #
--   #     #   #  #     #  #    # #
-- #####    ###    #####   #####  #######


-- 10GbEthernet core top level

-- created by Pierre-Yves Droz 2006

------------------------------------------------------------------------------
-- ten_gb_eth.vhd
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.all;

entity ten_gb_eth is
	generic(
		CONNECTOR             : integer              := 0;
		PREEMPHASYS           : string               := "3";
		SWING                 : string               := "800";
		USE_XILINX_MAC        : integer              := 1;
		USE_UCB_MAC           : integer              := 0;
		C_BASEADDR            : std_logic_vector     := X"FFFFFFFF";
		C_HIGHADDR            : std_logic_vector     := X"00000000";
		C_PLB_AWIDTH          : integer              := 32;
		C_PLB_DWIDTH          : integer              := 64;
		C_PLB_NUM_MASTERS     : integer              := 8;
		C_PLB_MID_WIDTH       : integer              := 3;
		C_FAMILY              : string               := "virtex2p"
	);
	port (
		-- application clock
		clk                   : in  std_logic;
		-- application reset
		rst                   : in  std_logic;

		-- tx ports
		tx_valid              : in  std_logic                      := '0';
		tx_ack                : out std_logic;
		tx_end_of_frame       : in  std_logic                      := '0';
		tx_discard            : in  std_logic                      := '0';
		tx_data               : in  std_logic_vector(63 downto 0);
		tx_dest_ip            : in  std_logic_vector(31 downto 0);
		tx_dest_port          : in  std_logic_vector(15 downto 0);
		
		-- rx port
		rx_valid              : out std_logic;
		rx_ack                : in  std_logic                      := '0';
		rx_data               : out std_logic_vector(63 downto 0);
		rx_end_of_frame       : out std_logic;
		rx_size               : out std_logic_vector(15 downto 0);
		rx_source_ip          : out std_logic_vector(31 downto 0);
		rx_source_port        : out std_logic_vector(15 downto 0);

		-- communication clocks
		mgt_clk_top_10G       : in  std_logic;
		mgt_clk_bottom_10G    : in  std_logic;
		mgt_clk_top_8G        : in  std_logic;
		mgt_clk_bottom_8G     : in  std_logic;
		xgmii_clk_top         : in  std_logic;
		xgmii_clk_bottom      : in  std_logic;
		speed_select          : in  std_logic;

		-- status led
		led_up                : out std_logic;
		led_rx                : out std_logic;
		led_tx                : out std_logic;

		-- MGT ports
		mgt_tx_l0_p           : out std_logic;
		mgt_tx_l0_n           : out std_logic;
		mgt_tx_l1_p           : out std_logic;
		mgt_tx_l1_n           : out std_logic;
		mgt_tx_l2_p           : out std_logic;
		mgt_tx_l2_n           : out std_logic;
		mgt_tx_l3_p           : out std_logic;
		mgt_tx_l3_n           : out std_logic;
		mgt_rx_l0_p           : in  std_logic;
		mgt_rx_l0_n           : in  std_logic;
		mgt_rx_l1_p           : in  std_logic;
		mgt_rx_l1_n           : in  std_logic;
		mgt_rx_l2_p           : in  std_logic;
		mgt_rx_l2_n           : in  std_logic;
		mgt_rx_l3_p           : in  std_logic;
		mgt_rx_l3_n           : in  std_logic;

		-- PLB attachment
		PLB_Clk               : in  std_logic;
		PLB_Rst               : in  std_logic;
		Sl_addrAck            : out std_logic;
		Sl_MBusy              : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
		Sl_MErr               : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
		Sl_rdBTerm            : out std_logic;
		Sl_rdComp             : out std_logic;
		Sl_rdDAck             : out std_logic;
		Sl_rdDBus             : out std_logic_vector(0 to C_PLB_DWIDTH-1);
		Sl_rdWdAddr           : out std_logic_vector(0 to 3);
		Sl_rearbitrate        : out std_logic;
		Sl_SSize              : out std_logic_vector(0 to 1);
		Sl_wait               : out std_logic;
		Sl_wrBTerm            : out std_logic;
		Sl_wrComp             : out std_logic;
		Sl_wrDAck             : out std_logic;
		PLB_abort             : in  std_logic;
		PLB_ABus              : in  std_logic_vector(0 to C_PLB_AWIDTH-1);
		PLB_BE                : in  std_logic_vector(0 to C_PLB_DWIDTH/8-1);
		PLB_busLock           : in  std_logic;
		PLB_compress          : in  std_logic;
		PLB_guarded           : in  std_logic;
		PLB_lockErr           : in  std_logic;
		PLB_masterID          : in  std_logic_vector(0 to C_PLB_MID_WIDTH-1);
		PLB_MSize             : in  std_logic_vector(0 to 1);
		PLB_ordered           : in  std_logic;
		PLB_PAValid           : in  std_logic;
		PLB_pendPri           : in  std_logic_vector(0 to 1);
		PLB_pendReq           : in  std_logic;
		PLB_rdBurst           : in  std_logic;
		PLB_rdPrim            : in  std_logic;
		PLB_reqPri            : in  std_logic_vector(0 to 1);
		PLB_RNW               : in  std_logic;
		PLB_SAValid           : in  std_logic;
		PLB_size              : in  std_logic_vector(0 to 3);
		PLB_type              : in  std_logic_vector(0 to 2);
		PLB_wrBurst           : in  std_logic;
		PLB_wrDBus            : in  std_logic_vector(0 to C_PLB_DWIDTH-1);
		PLB_wrPrim            : in  std_logic
	);
end entity ten_gb_eth;

architecture ten_gb_eth_arch of ten_gb_eth is

--  ####    ####   #    #   ####    #####
-- #    #  #    #  ##   #  #          #
-- #       #    #  # #  #   ####      #
-- #       #    #  #  # #       #     #
-- #    #  #    #  #   ##  #    #     #
--  ####    ####   #    #   ####      #

	type tx_fsm_state is (
			IDLE,
			SEND_HDR_WORD_1,
			SEND_HDR_WORD_2,
			SEND_HDR_WORD_3,
			SEND_HDR_WORD_4,
			SEND_HDR_WORD_5,
			SEND_HDR_WORD_6,
			SEND_DATA,
			SEND_LAST,
			SEND_CPU_DATA
		);

	type rx_fsm_state is (
			IDLE,
			RECEIVE_HDR_WORD_2,
			RECEIVE_HDR_WORD_3,
			RECEIVE_HDR_WORD_4,
			RECEIVE_HDR_WORD_5,
			RECEIVE_HDR_WORD_6,
			RECEIVE_DATA
		);

	type size_array is array (1 downto 0) of std_logic_vector(7 downto 0);

--  ####    ####   #    #  #####    ####   #    #  ######  #    #   #####   ####
-- #    #  #    #  ##  ##  #    #  #    #  ##   #  #       ##   #     #    #
-- #       #    #  # ## #  #    #  #    #  # #  #  #####   # #  #     #     ####
-- #       #    #  #    #  #####   #    #  #  # #  #       #  # #     #         #
-- #    #  #    #  #    #  #       #    #  #   ##  #       #   ##     #    #    #
--  ####    ####   #    #  #        ####   #    #  ######  #    #     #     ####

	-- 10 Gb Ethernet MAC (Xilinx)
	component ten_gig_eth_mac_v8_0
		port (
			reset                : in  std_logic;
			tx_underrun          : in  std_logic;
			tx_data              : in  std_logic_vector(63 downto 0);
			tx_data_valid        : in  std_logic_vector(7 downto 0);
			tx_start             : in  std_logic;
			tx_ack               : out std_logic;
			tx_ifg_delay         : in  std_logic_vector(7 downto 0);
			tx_statistics_vector : out std_logic_vector(24 downto 0);
			tx_statistics_valid  : out std_logic;
			rx_data              : out std_logic_vector(63 downto 0);
			rx_data_valid        : out std_logic_vector(7 downto 0);
			rx_good_frame        : out std_logic;
			rx_bad_frame         : out std_logic;
			rx_statistics_vector : out std_logic_vector(28 downto 0);
			rx_statistics_valid  : out std_logic;
			pause_val            : in  std_logic_vector(15 downto 0);
			pause_req            : in  std_logic;
			configuration_vector : in  std_logic_vector(66 downto 0);
			tx_clk0              : in  std_logic;
			tx_dcm_lock          : in  std_logic;
			xgmii_txd            : out std_logic_vector(63 downto 0);
			xgmii_txc            : out std_logic_vector(7 downto 0);
			rx_clk0              : in  std_logic;
			rx_dcm_lock          : in  std_logic;
			xgmii_rxd            : in  std_logic_vector(63 downto 0);
			xgmii_rxc            : in  std_logic_vector(7 downto 0)
		);
	end component;

	-- 10 Gb Ethernet MAC (UCB)
	component ten_gig_eth_mac_UCB
		port (
			reset                : in  std_logic;
			tx_underrun          : in  std_logic;
			tx_data              : in  std_logic_vector(63 downto 0);
			tx_data_valid        : in  std_logic_vector(7 downto 0);
			tx_start             : in  std_logic;
			tx_ack               : out std_logic;
			tx_ifg_delay         : in  std_logic_vector(7 downto 0);
			tx_statistics_vector : out std_logic_vector(24 downto 0);
			tx_statistics_valid  : out std_logic;
			rx_data              : out std_logic_vector(63 downto 0);
			rx_data_valid        : out std_logic_vector(7 downto 0);
			rx_good_frame        : out std_logic;
			rx_bad_frame         : out std_logic;
			rx_statistics_vector : out std_logic_vector(28 downto 0);
			rx_statistics_valid  : out std_logic;
			pause_val            : in  std_logic_vector(15 downto 0);
			pause_req            : in  std_logic;
			configuration_vector : in  std_logic_vector(66 downto 0);
			tx_clk0              : in  std_logic;
			tx_dcm_lock          : in  std_logic;
			xgmii_txd            : out std_logic_vector(63 downto 0);
			xgmii_txc            : out std_logic_vector(7 downto 0);
			rx_clk0              : in  std_logic;
			rx_dcm_lock          : in  std_logic;
			xgmii_rxd            : in  std_logic_vector(63 downto 0);
			xgmii_rxc            : in  std_logic_vector(7 downto 0)
		);
	end component;

	-- 10 Gb Ethernet PHY (XAUI)
	component xaui_v6_2
		port (
			reset                : in  std_logic;
			xgmii_txd            : in  std_logic_vector(63 downto 0);
			xgmii_txc            : in  std_logic_vector(7 downto 0);
			xgmii_rxd            : out std_logic_vector(63 downto 0);
			xgmii_rxc            : out std_logic_vector(7 downto 0);
			usrclk               : in  std_logic;
			mgt_txdata           : out std_logic_vector(63 downto 0);
			mgt_txcharisk        : out std_logic_vector(7 downto 0);
			mgt_rxdata           : in  std_logic_vector(63 downto 0);
			mgt_rxcharisk        : in  std_logic_vector(7 downto 0);
			mgt_codevalid        : in  std_logic_vector(7 downto 0);
			mgt_codecomma        : in  std_logic_vector(7 downto 0);
			mgt_enable_align     : out std_logic_vector(3 downto 0);
			mgt_enchansync       : out std_logic;
			mgt_syncok           : in  std_logic_vector(3 downto 0);
			mgt_loopback         : out std_logic;
			mgt_powerdown        : out std_logic;
			mgt_tx_reset         : in  std_logic_vector(3 downto 0);
			mgt_rx_reset         : in  std_logic_vector(3 downto 0);
			signal_detect        : in  std_logic_vector(3 downto 0);
			align_status         : out std_logic;
			sync_status          : out std_logic_vector(3 downto 0);
			configuration_vector : in  std_logic_vector(6 downto 0);
			status_vector        : out std_logic_vector(7 downto 0)
		);
	end component;

	-- 10Gb Ethernet Transceiver (MGT)
	component transceiver
		generic (
			CHBONDMODE           : string;
			CONNECTOR            : integer;
			CHANNEL              : integer;
			PREEMPHASYS          : string;
			SWING                : string
		);
		port (
			reset                           : in  std_logic;
			clk                             : in  std_logic;
			brefclk                         : in  std_logic;
			brefclk2                        : in  std_logic;
			refclksel                       : in  std_logic;
			dcm_locked                      : in  std_logic;
			txdata                          : in  std_logic_vector(15 downto 0);
			txcharisk                       : in  std_logic_vector(1 downto 0);
			txp                             : out std_logic;
			txn                             : out std_logic;
			rxdata                          : out std_logic_vector(15 downto 0);
			rxcharisk                       : out std_logic_vector(1 downto 0);
			rxp                             : in  std_logic;
			rxn                             : in  std_logic;
			loopback_ser                    : in  std_logic;
			powerdown                       : in  std_logic;
			chbondi                         : in  std_logic_vector(3 downto 0);
			chbondo                         : out std_logic_vector(3 downto 0);
			enable_align                    : in  std_logic;
			syncok                          : out std_logic;
			enchansync                      : in  std_logic;
			code_valid                      : out std_logic_vector(1 downto 0);
			code_comma                      : out std_logic_vector(1 downto 0);
			mgt_tx_reset                    : out std_logic;
			mgt_rx_reset                    : out std_logic
		);
	end component;

	-- packet buffer
	component packet_buffer
		port (
			clka                            : in  std_logic;
			dina                            : in  std_logic_vector(64 downto 0);
			addra                           : in  std_logic_vector(10 downto 0);
			wea                             : in  std_logic_vector(0  downto 0);
			clkb                            : in  std_logic;
			addrb                           : in  std_logic_vector(10 downto 0);
			doutb                           : out std_logic_vector(64 downto 0)
		);
	end component;

	component packet_buffer_cpu
		port (
			clka                            : in  std_logic;
			dina                            : in  std_logic_vector(63 downto 0);
			addra                           : in  std_logic_vector(8  downto 0);
			wea                             : in  std_logic_vector(0  downto 0);
			douta                           : out std_logic_vector(63 downto 0);
			clkb                            : in  std_logic;
			dinb                            : in  std_logic_vector(63 downto 0);
			addrb                           : in  std_logic_vector(8  downto 0);
			web                             : in  std_logic_vector(0  downto 0);
			doutb                           : out std_logic_vector(63 downto 0)
		);
	end component;

	-- address_fifos
	component address_fifo
		port (
			din                             : in  std_logic_vector(63 downto 0);
			rd_clk                          : in  std_logic;
			rd_en                           : in  std_logic;
			valid                           : out std_logic;
			rst                             : in  std_logic;
			wr_clk                          : in  std_logic;
			wr_en                           : in  std_logic;
			dout                            : out std_logic_vector(63 downto 0);
			empty                           : out std_logic;
			full                            : out std_logic
		);
	end component;

	-- ARP cache
	component arp_cache
		port (
			clka                            : in  std_logic;
			dina                            : in  std_logic_vector(47 downto 0);
			addra                           : in  std_logic_vector( 7 downto 0);
			wea                             : in  std_logic_vector( 0 downto 0);
			douta                           : out std_logic_vector(47 downto 0);
			clkb                            : in  std_logic;
			dinb                            : in  std_logic_vector(47 downto 0);
			addrb                           : in  std_logic_vector( 7 downto 0);
			web                             : in  std_logic_vector( 0 downto 0);
			doutb                           : out std_logic_vector(47 downto 0)
		);
	end component;

	-- retimer
	component retimer
		generic(
			WIDTH                           : integer           := 32
		);
		port (
			src_clk                         : in  std_logic;
			src_data                        : in  std_logic_vector(WIDTH-1 downto 0);
			dest_clk                        : in  std_logic;
			dest_data                       : out std_logic_vector(WIDTH-1 downto 0);
			dest_new_data                   : out std_logic
		);
	end component;

	-- plb attachment
	component plb_attach
		generic(
			C_BASEADDR            : std_logic_vector     := X"FFFFFFFF";
			C_HIGHADDR            : std_logic_vector     := X"00000000";
			C_PLB_AWIDTH          : integer              := 32;
			C_PLB_DWIDTH          : integer              := 64;
			C_PLB_NUM_MASTERS     : integer              := 8;
			C_PLB_MID_WIDTH       : integer              := 3;
			C_FAMILY              : string               := "virtex2p"
		);
		port (
			-- local configuration
			local_mac             : out std_logic_vector(47 downto 0);
			local_ip              : out std_logic_vector(31 downto 0);
			local_gateway         : out std_logic_vector( 7 downto 0);
			local_port            : out std_logic_vector(15 downto 0);
			local_valid           : out std_logic;

			-- tx buffer
			tx_buffer_data_in     : out std_logic_vector(63 downto 0);
			tx_buffer_address     : out std_logic_vector( 8 downto 0);
			tx_buffer_we          : out std_logic;
			tx_buffer_data_out    : in  std_logic_vector(63 downto 0);
			tx_cpu_buffer_size    : out std_logic_vector(7 downto 0) := (others => '0');
			tx_cpu_free_buffer    : in  std_logic := '0';
			tx_cpu_buffer_filled  : out std_logic; 
			tx_cpu_buffer_select  : in  std_logic := '0';

			-- rx buffer
			rx_buffer_data_in     : out std_logic_vector(63 downto 0);
			rx_buffer_address     : out std_logic_vector( 8 downto 0);
			rx_buffer_we          : out std_logic;
			rx_buffer_data_out    : in  std_logic_vector(63 downto 0);
			rx_cpu_buffer_size    : in  std_logic_vector( 7 downto 0);
			rx_cpu_new_buffer     : in  std_logic;
			rx_cpu_buffer_cleared : out std_logic;
			rx_cpu_buffer_select  : in  std_logic;

			-- ARP cache
			arp_cache_data_in     : out std_logic_vector(47 downto 0);
			arp_cache_address     : out std_logic_vector( 7 downto 0); 
			arp_cache_we          : out std_logic;                    
			arp_cache_data_out    : in  std_logic_vector(47 downto 0);
			
			-- PLB attachment
			PLB_Clk               : in  std_logic;
			PLB_Rst               : in  std_logic;
			Sl_addrAck            : out std_logic;
			Sl_MBusy              : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
			Sl_MErr               : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
			Sl_rdBTerm            : out std_logic;
			Sl_rdComp             : out std_logic;
			Sl_rdDAck             : out std_logic;
			Sl_rdDBus             : out std_logic_vector(0 to C_PLB_DWIDTH-1);
			Sl_rdWdAddr           : out std_logic_vector(0 to 3);
			Sl_rearbitrate        : out std_logic;
			Sl_SSize              : out std_logic_vector(0 to 1);
			Sl_wait               : out std_logic;
			Sl_wrBTerm            : out std_logic;
			Sl_wrComp             : out std_logic;
			Sl_wrDAck             : out std_logic;
			PLB_abort             : in  std_logic;
			PLB_ABus              : in  std_logic_vector(0 to C_PLB_AWIDTH-1);
			PLB_BE                : in  std_logic_vector(0 to C_PLB_DWIDTH/8-1);
			PLB_busLock           : in  std_logic;
			PLB_compress          : in  std_logic;
			PLB_guarded           : in  std_logic;
			PLB_lockErr           : in  std_logic;
			PLB_masterID          : in  std_logic_vector(0 to C_PLB_MID_WIDTH-1);
			PLB_MSize             : in  std_logic_vector(0 to 1);
			PLB_ordered           : in  std_logic;
			PLB_PAValid           : in  std_logic;
			PLB_pendPri           : in  std_logic_vector(0 to 1);
			PLB_pendReq           : in  std_logic;
			PLB_rdBurst           : in  std_logic;
			PLB_rdPrim            : in  std_logic;
			PLB_reqPri            : in  std_logic_vector(0 to 1);
			PLB_RNW               : in  std_logic;
			PLB_SAValid           : in  std_logic;
			PLB_size              : in  std_logic_vector(0 to 3);
			PLB_type              : in  std_logic_vector(0 to 2);
			PLB_wrBurst           : in  std_logic;
			PLB_wrDBus            : in  std_logic_vector(0 to C_PLB_DWIDTH-1);
			PLB_wrPrim            : in  std_logic
		);
	end component;

--  ####      #     ####   #    #    ##    #        ####
-- #          #    #    #  ##   #   #  #   #       #
--  ####      #    #       # #  #  #    #  #        ####
--      #     #    #  ###  #  # #  ######  #            #
-- #    #     #    #    #  #   ##  #    #  #       #    #
--  ####      #     ####   #    #  #    #  ######   ####



	-- clocks
	signal xgmii_clk                               : std_logic := '0';

	-- resets
	signal xgmii_rst                               : std_logic := '1';
	signal xgmii_rst_0                             : std_logic := '1';
	signal xgmii_rst_1                             : std_logic := '1';
	signal xgmii_rst_2                             : std_logic := '1';
	signal xgmii_rst_3                             : std_logic := '1';

	-- PHY <-> MGT signals
	signal mgt_brefclk                             : std_logic;
	signal mgt_brefclk2                            : std_logic;
	signal mgt_txdata                              : std_logic_vector(63 downto 0);
	signal mgt_txcharisk                           : std_logic_vector(7 downto 0);
	signal mgt_tx_reset                            : std_logic_vector(3 downto 0);
	signal mgt_rxdata                              : std_logic_vector(63 downto 0);
	signal mgt_rxcharisk                           : std_logic_vector(7 downto 0);
	signal mgt_enable_align                        : std_logic_vector(3 downto 0);
	signal mgt_syncok                              : std_logic_vector(3 downto 0);
	signal mgt_enchansync                          : std_logic;
	signal mgt_codevalid                           : std_logic_vector(7 downto 0);
	signal mgt_codecomma                           : std_logic_vector(7 downto 0);
	signal mgt_rx_reset                            : std_logic_vector(3 downto 0);
	signal mgt_loopback                            : std_logic;
	signal mgt_powerdown                           : std_logic;
	signal mgt_chbond                              : std_logic_vector(3 downto 0);

	-- PHY signals
	signal phy_configuration_vector                : std_logic_vector(6 downto 0);
	signal phy_status_vector                       : std_logic_vector(7 downto 0);
	signal phy_rx_up                               : std_logic;

	-- MAC <-> PHY signals
	signal xgmii_tx_data                           : std_logic_vector(63 downto 0) := X"0707070707070707";
	signal xgmii_tx_ctrl                           : std_logic_vector(7 downto 0)  := "11111111";
	signal xgmii_rx_data                           : std_logic_vector(63 downto 0);
	signal xgmii_rx_ctrl                           : std_logic_vector(7 downto 0); 
	
	-- MAC signals
	signal mac_flow_pause_val                      : std_logic_vector(15 downto 0);
	signal mac_flow_pause_req                      : std_logic;
	signal mac_configuration_vector                : std_logic_vector(66 downto 0);

	-- MAC <-> Buffers signals
	signal mac_tx_underrun                         : std_logic;
	signal mac_tx_data                             : std_logic_vector(63 downto 0);
	signal mac_tx_data_valid                       : std_logic_vector(7 downto 0) := (others => '0');
	signal mac_tx_start                            : std_logic := '0';
	signal mac_tx_ack                              : std_logic;
	signal mac_tx_ifg_delay                        : std_logic_vector(7 downto 0);
	signal mac_tx_statistics_vector                : std_logic_vector(24 downto 0);
	signal mac_tx_statistics_valid                 : std_logic;
	signal mac_rx_data                             : std_logic_vector(63 downto 0);
	signal mac_rx_data_R                           : std_logic_vector(63 downto 0);
	signal mac_rx_data_valid                       : std_logic_vector(7 downto 0);
	signal mac_rx_data_valid_R                     : std_logic_vector(7 downto 0);
	signal mac_rx_good_frame                       : std_logic;
	signal mac_rx_bad_frame                        : std_logic;
	signal mac_rx_statistics_vector                : std_logic_vector(28 downto 0);
	signal mac_rx_statistics_valid                 : std_logic;

	-- TX controller signals
	signal tx_state                                : tx_fsm_state := IDLE;
	signal tx_buffer_write_data                    : std_logic_vector(64 downto 0);
	signal tx_buffer_write_address                 : std_logic_vector(10 downto 0) := (others => '0');
	signal tx_buffer_write_address_snapshot        : std_logic_vector(10 downto 0) := (others => '0');
	signal tx_buffer_we                            : std_logic_vector(0  downto 0);
	signal tx_buffer_read_address                  : std_logic_vector(10 downto 0) := (others => '0');
	signal tx_buffer_read_data                     : std_logic_vector(64 downto 0);
	signal tx_buffer_read_data_R                   : std_logic_vector(64 downto 0);
	signal tx_buffer_read_address_minustwo         : std_logic_vector(10 downto 0);
	signal tx_buffer_read_address_minustwo_retimed : std_logic_vector(10 downto 0);
	signal tx_buffer_new_read_address              : std_logic;
	signal tx_buffer_full                          : std_logic;
	signal tx_addrfifo_read_en                     : std_logic;
	signal tx_addrfifo_read_data                   : std_logic_vector(63 downto 0);
	signal tx_addrfifo_valid                       : std_logic;
	signal tx_addrfifo_we                          : std_logic;
	signal tx_addrfifo_full                        : std_logic;
	signal tx_addrfifo_write_data                  : std_logic_vector(63 downto 0);
	signal tx_data_count                           : std_logic_vector(15 downto 0) := (others => '0');
	signal tx_ip_length                            : std_logic_vector(15 downto 0) := (others => '0');
	signal tx_udp_length                           : std_logic_vector(15 downto 0) := (others => '0');
	signal tx_ip_checksum_0                        : std_logic_vector(17 downto 0) := (others => '0');
	signal tx_ip_checksum_1                        : std_logic_vector(16 downto 0) := (others => '0');
	signal tx_ip_checksum                          : std_logic_vector(15 downto 0) := (others => '0');
	signal tx_ip_checksum_fixed_0                  : std_logic_vector(17 downto 0);
	signal tx_ip_checksum_fixed_1                  : std_logic_vector(16 downto 0);
	signal tx_ip_checksum_fixed                    : std_logic_vector(15 downto 0);
	signal tx_buffer_cpu_read_address              : std_logic_vector( 7 downto 0);
	signal tx_buffer_cpu_read_address_complete     : std_logic_vector( 8 downto 0);
	signal tx_buffer_cpu_read_address_sequential   : std_logic_vector( 7 downto 0);
	signal tx_buffer_cpu_read_data                 : std_logic_vector(63 downto 0);
	signal tx_cpu_free_buffer                      : std_logic;
	signal tx_cpu_buffer_filled                    : std_logic;
	signal tx_cpu_buffer_filled_pre                : std_logic;
	signal tx_cpu_got_ack                          : std_logic;
	signal tx_arp_cache_address                    : std_logic_vector( 7 downto 0);
	signal tx_arp_cache_read_data                  : std_logic_vector(47 downto 0);
	signal tx_cpu_buffer_sizes                     : size_array := (0=> X"00", 1=> X"00");
	signal tx_cpu_buffer_size                      : std_logic_vector( 7 downto 0) := (others => '0');
	signal tx_cpu_buffer_current                   : std_logic;
	signal tx_cpu_buffer_next                      : std_logic := '0';
	signal tx_cpu_buffer_valid                     : std_logic_vector( 1 downto 0) := "00";

	-- RX controller signals
	signal rx_state                                : rx_fsm_state := IDLE;
	signal rx_buffer_write_data                    : std_logic_vector(64 downto 0);
	signal rx_buffer_write_address                 : std_logic_vector(10 downto 0) := (others => '0');
	signal rx_buffer_write_address_R               : std_logic_vector(10 downto 0) := (others => '0');
	signal rx_buffer_write_address_snapshot        : std_logic_vector(10 downto 0) := (others => '0');
	signal rx_buffer_we                            : std_logic_vector(0  downto 0);
	signal rx_buffer_read_address                  : std_logic_vector(10 downto 0) := (others => '0');
	signal rx_buffer_read_address_sequential       : std_logic_vector(10 downto 0) := (others => '0');
	signal rx_buffer_read_data                     : std_logic_vector(64 downto 0);
	signal rx_buffer_read_address_minusone         : std_logic_vector(10 downto 0);
	signal rx_buffer_read_address_minusone_retimed : std_logic_vector(10 downto 0);
	signal rx_buffer_full                          : std_logic;
	signal rx_addrfifo_read_en                     : std_logic;
	signal rx_addrfifo_read_data                   : std_logic_vector(63 downto 0);
	signal rx_addrfifo_valid                       : std_logic;
	signal rx_addrfifo_we                          : std_logic;
	signal rx_addrfifo_full                        : std_logic;
	signal rx_addrfifo_write_data                  : std_logic_vector(63 downto 0) := (others => '0');
	signal rx_frame_valid_for_hardware             : std_logic := '0';
	signal rx_frame_valid_for_cpu                  : std_logic := '0';
	signal rx_valid_ack                            : std_logic;
	signal rx_destination_mac                      : std_logic_vector(47 downto 0);
	signal rx_destination_ip                       : std_logic_vector(31 downto 0);
	signal rx_destination_port                     : std_logic_vector(15 downto 0);
	signal rx_buffer_cpu_write_data                : std_logic_vector(63 downto 0);
	signal rx_buffer_cpu_write_address             : std_logic_vector(7 downto 0) := (others => '0');
	signal rx_buffer_cpu_write_address_complete    : std_logic_vector(8 downto 0);
	signal rx_buffer_cpu_we                        : std_logic_vector(0 downto 0);
	signal rx_cpu_buffer_cleared                   : std_logic;
	signal rx_cpu_buffer_cleared_pre               : std_logic;
	signal rx_cpu_new_buffer                       : std_logic;
	signal rx_cpu_buffer_sizes                     : size_array := (0=> X"00", 1=> X"00");
	signal rx_cpu_buffer_size                      : std_logic_vector( 7 downto 0) := (others => '0');
	signal rx_cpu_buffer_current                   : std_logic;
	signal rx_cpu_buffer_last                      : std_logic := '0';
	signal rx_cpu_buffer_valid                     : std_logic_vector(1 downto 0) := "00";

	-- CPU signals
	signal local_mac                               : std_logic_vector(47 downto 0);
	signal local_ip                                : std_logic_vector(31 downto 0);
	signal local_gateway                           : std_logic_vector( 7 downto 0);
	signal local_port                              : std_logic_vector(15 downto 0);
	signal local_valid                             : std_logic;
	signal local_valid_retimed                     : std_logic;
	signal cpu_tx_buffer_data_in                   : std_logic_vector(63 downto 0);
	signal cpu_tx_buffer_address                   : std_logic_vector( 8 downto 0);
	signal cpu_tx_buffer_we                        : std_logic_vector( 0 downto 0);
	signal cpu_tx_buffer_data_out                  : std_logic_vector(63 downto 0);
	signal cpu_tx_cpu_free_buffer                  : std_logic;
	signal cpu_tx_cpu_free_buffer_pre              : std_logic;
	signal cpu_tx_cpu_buffer_size                  : std_logic_vector(7 downto 0);
	signal cpu_tx_cpu_buffer_filled                : std_logic;
	signal cpu_tx_cpu_buffer_select                : std_logic;
	signal cpu_rx_buffer_data_in                   : std_logic_vector(63 downto 0);
	signal cpu_rx_buffer_address                   : std_logic_vector( 8 downto 0);
	signal cpu_rx_buffer_we                        : std_logic_vector( 0 downto 0);
	signal cpu_rx_buffer_data_out                  : std_logic_vector(63 downto 0);
	signal cpu_rx_cpu_new_buffer                   : std_logic;
	signal cpu_rx_cpu_new_buffer_pre               : std_logic;
	signal cpu_rx_cpu_buffer_size                  : std_logic_vector(7 downto 0) := (others => '0');
	signal cpu_rx_cpu_buffer_cleared               : std_logic;
	signal cpu_rx_cpu_buffer_select                : std_logic;
	signal cpu_arp_cache_data_in                   : std_logic_vector(47 downto 0);
	signal cpu_arp_cache_address                   : std_logic_vector( 7 downto 0); 
	signal cpu_arp_cache_we                        : std_logic_vector( 0 downto 0);                    
	signal cpu_arp_cache_data_out                  : std_logic_vector(47 downto 0);


	-- LEDs signals
	signal led_rx_count                            : std_logic_vector(23 downto 0) := (others => '0');
	signal led_tx_count                            : std_logic_vector(23 downto 0) := (others => '0');
	signal led_rx_1                                : std_logic := '0';
	signal led_tx_1                                : std_logic := '0';
	signal led_up_1                                : std_logic := '0';

	-- constraints
	attribute keep                                 : string;
	attribute keep of rx_cpu_buffer_cleared_pre    : signal is "true";
	attribute keep of cpu_rx_cpu_new_buffer_pre    : signal is "true";
	attribute keep of tx_cpu_buffer_filled_pre     : signal is "true";
	attribute keep of cpu_tx_cpu_free_buffer_pre   : signal is "true";

begin
--  ####   #        ####    ####   #    #   ####
-- #    #  #       #    #  #    #  #   #   #
-- #       #       #    #  #       ####     ####
-- #       #       #    #  #       #  #         #
-- #    #  #       #    #  #    #  #   #   #    #
--  ####   ######   ####    ####   #    #   ####

-- physical layer clocks
genclk0 : if (CONNECTOR = 0 or CONNECTOR = 1) generate
	mgt_brefclk     <= mgt_clk_top_8G;
	mgt_brefclk2    <= mgt_clk_top_10G;
	xgmii_clk       <= xgmii_clk_top;
end generate;

genclk1 : if (CONNECTOR = 2 or CONNECTOR = 3) generate
	mgt_brefclk     <= mgt_clk_bottom_8G;
	mgt_brefclk2    <= mgt_clk_bottom_10G;
	xgmii_clk       <= xgmii_clk_bottom;
end generate;
 
-- #####   ######   ####   ######   #####
-- #    #  #       #       #          #
-- #    #  #####    ####   #####      #
-- #####   #            #  #          #
-- #   #   #       #    #  #          #
-- #    #  ######   ####   ######     #

-- generate an internal version of the reset
reset_proc: process(xgmii_clk)
begin
	if xgmii_clk'event and xgmii_clk = '1' then
		if rst = '1' then
			xgmii_rst    <= '1';
			xgmii_rst_0  <= '1';
			xgmii_rst_1  <= '1';
			xgmii_rst_2  <= '1';
			xgmii_rst_3  <= '1';
		else
			xgmii_rst    <= xgmii_rst_0;
			xgmii_rst_0  <= xgmii_rst_1;
			xgmii_rst_1  <= xgmii_rst_2;
			xgmii_rst_2  <= xgmii_rst_3;
			xgmii_rst_3  <= '0';
		end if;
	end if;
end process;

--  #####  #    #           ####    #####  #####   #
--    #     #  #           #    #     #    #    #  #
--    #      ##            #          #    #    #  #
--    #      ##            #          #    #####   #
--    #     #  #           #    #     #    #   #   #
--    #    #    #           ####      #    #    #  ######

-- transmit data buffer
tx_buffer: packet_buffer
	port map (
		clka     => clk,
		dina     => tx_buffer_write_data,
		addra    => tx_buffer_write_address,
		wea      => tx_buffer_we,
		
		clkb     => xgmii_clk,
		addrb    => tx_buffer_read_address,
		doutb    => tx_buffer_read_data
	);

-- transmit CPU data buffer
tx_buffer_cpu: packet_buffer_cpu
	port map (
		clka     => PLB_Clk,
		dina     => cpu_tx_buffer_data_in,
		addra    => cpu_tx_buffer_address,
		wea      => cpu_tx_buffer_we,
		douta    => cpu_tx_buffer_data_out,
		
		clkb     => xgmii_clk,
		dinb     => X"0000000000000000",
		addrb    => tx_buffer_cpu_read_address_complete,
		web      => "0",
		doutb    => tx_buffer_cpu_read_data
	);

-- transmit address fifo
tx_address_fifo: address_fifo
	port map (
		rst      => rst,

		rd_clk   => xgmii_clk,
		rd_en    => tx_addrfifo_read_en,
		dout     => tx_addrfifo_read_data,
		valid    => tx_addrfifo_valid,
		
		wr_clk   => clk,
		wr_en    => tx_addrfifo_we,
		full     => tx_addrfifo_full,
		din      => tx_addrfifo_write_data
	);

-- read address retimer
tx_read_address_retimer: retimer
	generic map (
		WIDTH     => 11
	)
	port map (
		src_clk       => xgmii_clk,
		src_data      => tx_buffer_read_address_minustwo,
		dest_clk      => clk,
		dest_data     => tx_buffer_read_address_minustwo_retimed,
		dest_new_data => tx_buffer_new_read_address
	);

-- ARP cache
tx_arp_cache: arp_cache
	port map (
		clka      => PLB_Clk,
		dina      => cpu_arp_cache_data_in,
		addra     => cpu_arp_cache_address,
		wea       => cpu_arp_cache_we,
		douta     => cpu_arp_cache_data_out,
		
		clkb      => xgmii_clk,
		dinb      => X"000000000000",
		addrb     => tx_arp_cache_address,
		web       => "0",
		doutb     => tx_arp_cache_read_data
	);

-- *
-- * USER side
-- *

-- transmit user clock controller process
tx_user_proc: process(clk)
begin
	if clk'event and clk = '1' then
		if rst = '1' then
			tx_buffer_write_address          <= (others => '0');
			tx_buffer_write_address_snapshot <= (others => '0');
			tx_data_count                    <= (0 => '1', others => '0');
			tx_buffer_full                   <= '0';
		else
			-- the read counter advanced, so we can bring the full bit back to 0
			if tx_buffer_new_read_address = '1' then
				tx_buffer_full <= '0';
			end if;
			-- a valid write was issued
			if tx_valid = '1' and tx_addrfifo_full = '0' and tx_buffer_full = '0' and tx_discard = '0' then
				-- increment the write counter
				tx_buffer_write_address <= tx_buffer_write_address + 1;
				-- the transmit buffer will be full on the next cycle whenever the write address is two slots behind the read address
				if tx_buffer_write_address = tx_buffer_read_address_minustwo_retimed then
					tx_buffer_full <= '1';
				end if;
				-- increment the data count
				tx_data_count <= tx_data_count + 1;				
				-- a request to send the packet was issued
				if tx_end_of_frame = '1' then
					-- reset the data count
					tx_data_count <= (0 => '1', others => '0');
					-- snapshot the write address to be able to cancel the next packet
					tx_buffer_write_address_snapshot <= tx_buffer_write_address + 1;
				end if;
			end if;
			-- a packet was discarded
			if tx_discard = '1' then
					tx_buffer_write_address          <= tx_buffer_write_address_snapshot;
					tx_data_count                    <= (0=> '1', others => '0');
			end if;
		end if;
	end if;
end process;

-- the data we write to the buffer is directly the data given by the user plus the end of frame bit
tx_buffer_write_data                <= tx_end_of_frame & tx_data;
-- the transmit buffer can always be written as the write address always points to an empty slot
tx_buffer_we                        <= "1";
-- we ack the data whenever neither the address fifo nor the buffer is full and we received valid data
tx_ack                              <= '1' when tx_addrfifo_full = '0' and tx_buffer_full = '0' and tx_valid = '1' else '0';
-- complete cpu buffer address with buffer selection
tx_buffer_cpu_read_address_complete <= tx_cpu_buffer_current & tx_buffer_cpu_read_address;
-- we write data in the address fifo whenever we get a valid end of frame write
tx_addrfifo_we                      <= '1' when tx_addrfifo_full = '0' and tx_buffer_full = '0' and tx_end_of_frame = '1' and tx_discard = '0' and tx_valid = '1' else '0';
-- address and port are packed in the address fifo
tx_addrfifo_write_data              <= tx_data_count & tx_dest_port & tx_dest_ip;

-- *
-- * MAC side
-- *

-- transmit xgmii clock controller process
tx_xgmii_proc: process(xgmii_clk)
begin
	if xgmii_clk'event and xgmii_clk = '1' then
		-- register the data signals coming from the packet buffer
		tx_buffer_read_data_R <= tx_buffer_read_data;
		-- state machine		
		if xgmii_rst = '1' then
			tx_state                              <= IDLE;
			mac_tx_data_valid                     <= (others => '0');
			tx_buffer_read_address                <= (others => '0');
			tx_buffer_cpu_read_address_sequential <= (others => '0');
			tx_ip_length                          <= (others => '0');
			tx_ip_checksum                        <= (others => '0');
			tx_ip_checksum_0                      <= (others => '0');
			tx_udp_length                         <= (others => '0');
			tx_cpu_free_buffer                    <= '0';
			tx_cpu_buffer_current                 <= '0';
			tx_cpu_got_ack                        <= '0';
		else

			-- *
			-- * CPU Handshake			
			-- *
			-- 4-way handshake with the PLB interface
			-- if the current buffer is empty, we can swap the buffers and notify the CPU
			if tx_cpu_free_buffer = '0' and tx_cpu_buffer_filled = '0' and tx_cpu_buffer_valid(CONV_INTEGER(tx_cpu_buffer_current)) = '0' then
				tx_cpu_free_buffer        <= '1';
				tx_cpu_buffer_current     <= not tx_cpu_buffer_current;
				tx_cpu_buffer_next        <= tx_cpu_buffer_current;
			end if;
			-- if the CPU tells us that it is done with the buffer that it was filling then we flag it as valid
			if tx_cpu_free_buffer = '1' and tx_cpu_buffer_filled = '1' then
				tx_cpu_free_buffer        <= '0';
				tx_cpu_buffer_sizes(CONV_INTEGER(not tx_cpu_buffer_current)) <= tx_cpu_buffer_size;
				tx_cpu_buffer_valid(CONV_INTEGER(not tx_cpu_buffer_current)) <= '1';
			end if;

			-- *
			-- * Buffer control/packetization state machine
			-- *
			case tx_state is
				when IDLE            =>
					-- if the address fifo has anything for us and the local parameters are valid, we can safely assume that there is also data in the buffer and start a frame transmission
					if tx_addrfifo_valid = '1' and local_valid_retimed = '1' then
						-- the request for the MAC is done by combinatorial logic
						tx_state          <= SEND_HDR_WORD_1;							
						mac_tx_data_valid <= "11111111";
					end if;
					-- if the current cpu buffer is valid, we can start a frame transmission
					if tx_cpu_buffer_valid(CONV_INTEGER(tx_cpu_buffer_current)) = '1' then
						-- the request for the MAC is done by combinatorial logic
						tx_state          <= SEND_CPU_DATA;			
						mac_tx_data_valid <= "11111111";
					end if;
				when SEND_HDR_WORD_1 =>
					-- if the MAC is ready then we can send the rest of the header and the data
					if mac_tx_ack = '1' then
						tx_state          <= SEND_HDR_WORD_2;
					end if;
				when SEND_HDR_WORD_2 =>
					-- we can automatically jump to the next state
					tx_state          <= SEND_HDR_WORD_3;
				when SEND_HDR_WORD_3 =>
					-- we can automatically jump to the next state
					tx_state          <= SEND_HDR_WORD_4;
				when SEND_HDR_WORD_4 =>
					-- we can automatically jump to the next state
					tx_state          <= SEND_HDR_WORD_5;
				when SEND_HDR_WORD_5 =>
					-- we can automatically jump to the next state
					tx_state          <= SEND_HDR_WORD_6;
					-- we can start incrementing the packet buffer address
					tx_buffer_read_address  <= tx_buffer_read_address + 1;
				when SEND_HDR_WORD_6 =>
					-- we can automatically jump to the next state
					tx_state          <= SEND_DATA;
					-- if we reach the end of the frame then we send the last bytes and then we go back to idle
					if tx_buffer_read_data(64) = '1' then
						tx_state          <= SEND_LAST;
						mac_tx_data_valid <= "00000011";
					else
						-- increment the packet buffer address
						tx_buffer_read_address  <= tx_buffer_read_address + 1;
					end if;
				when SEND_DATA =>
					-- if we reach the end of the frame then we send the last bytes and then we go back to idle
					if tx_buffer_read_data(64) = '1' then
						tx_state          <= SEND_LAST;
						mac_tx_data_valid <= "00000011";
					else
						-- increment the packet buffer address
						tx_buffer_read_address  <= tx_buffer_read_address + 1;
					end if;
				when SEND_LAST =>
					-- we can automatically jump back to the IDLE state
					tx_state          <= IDLE;
					mac_tx_data_valid <= "00000000";
				when SEND_CPU_DATA =>
					if mac_tx_ack = '1' or tx_cpu_got_ack = '1' then
						if tx_buffer_cpu_read_address /= tx_cpu_buffer_size then
							tx_cpu_got_ack     <= '1';
							tx_buffer_cpu_read_address_sequential <= tx_buffer_cpu_read_address;
						else
							tx_cpu_got_ack        <= '0';
							tx_state              <= IDLE;
							mac_tx_data_valid     <= "00000000";
							tx_cpu_buffer_valid(CONV_INTEGER(tx_cpu_buffer_current)) <= '0';
							tx_buffer_cpu_read_address_sequential <= (others => '0');
						end if;
					end if;
			end case;
			-- compute the ip length
			tx_ip_length <= (tx_addrfifo_read_data(60 downto 48) & "000") + 28;
			-- compute the udp length
			tx_udp_length <= (tx_addrfifo_read_data(60 downto 48) & "000") + 8;
			-- compute the ip checksum (1's complement logic)
			tx_ip_checksum_0 <= ("00" & tx_ip_checksum_fixed                        )+
			                    ("00" & tx_ip_length                                )+
			                    ("00" & tx_addrfifo_read_data(31 downto 16)         )+
			                    ("00" & tx_addrfifo_read_data(15 downto 0)          );
			tx_ip_checksum_1 <= ("0"  & tx_ip_checksum_0(15 downto 0)               )+
			                    ("000000000000000" & tx_ip_checksum_0(17 downto 16) );
			tx_ip_checksum   <= not (
			                    (tx_ip_checksum_1(15 downto 0)                      )+
			                    ("000000000000000" & tx_ip_checksum_1(16)           ));

		end if;
	end if;
end process;

-- if we are IDLE and the address fifo has anything in stock we can issue a request for frame transmission to the MAC
mac_tx_start          <= '1' when tx_state = IDLE and ((tx_addrfifo_valid = '1' and local_valid_retimed = '1') or (tx_cpu_buffer_valid(CONV_INTEGER(tx_cpu_buffer_current)) = '1')) else '0';
-- ath the end of a frame transmission, we can ack the adress from the address fifo
tx_addrfifo_read_en   <= '1' when tx_state = SEND_LAST else '0';
-- substracts 2 to the read address before sending it to the retimer
tx_buffer_read_address_minustwo <= tx_buffer_read_address - 2;
-- selects what should be sent to the mac depending on the controller state
with tx_state select mac_tx_data <= 
		local_mac(39 downto 32) & local_mac(47 downto 40) & tx_arp_cache_read_data(7 downto 0) & tx_arp_cache_read_data(15 downto 8) & tx_arp_cache_read_data(23 downto 16) & tx_arp_cache_read_data(31 downto 24) & tx_arp_cache_read_data(39 downto 32) & tx_arp_cache_read_data(47 downto 40)                                   when SEND_HDR_WORD_1,
		X"00" & X"45" & X"00" & X"08" & local_mac(7 downto 0) & local_mac(15 downto 8) & local_mac(23 downto 16) & local_mac(31 downto 24)                                                                                                                                                                                         when SEND_HDR_WORD_2,
		X"11" & X"FF" & X"00" & X"40" & X"00" & X"00" & tx_ip_length(7 downto 0) & tx_ip_length(15 downto 8)                                                                                                                                                                                                                       when SEND_HDR_WORD_3,
		tx_addrfifo_read_data(23 downto 16) & tx_addrfifo_read_data(31 downto 24) & local_ip(7 downto 0) & local_ip(15 downto 8) & local_ip(23 downto 16) & local_ip(31 downto 24) & tx_ip_checksum(7 downto 0) & tx_ip_checksum(15 downto 8)                                                                                      when SEND_HDR_WORD_4,
		tx_udp_length(7 downto 0) & tx_udp_length(15 downto 8) & tx_addrfifo_read_data(39 downto 32) & tx_addrfifo_read_data(47 downto 40) & local_port(7 downto 0) & local_port(15 downto 8) & tx_addrfifo_read_data(7 downto 0) & tx_addrfifo_read_data(15 downto 8)                                                             when SEND_HDR_WORD_5,
		tx_buffer_read_data(23 downto 16) & tx_buffer_read_data(31 downto 24) & tx_buffer_read_data(39 downto 32) & tx_buffer_read_data(47 downto 40) & tx_buffer_read_data(55 downto 48) & tx_buffer_read_data(63 downto 56) & X"00" & X"00"                                                                                      when SEND_HDR_WORD_6,
		tx_buffer_read_data(23 downto 16) & tx_buffer_read_data(31 downto 24) & tx_buffer_read_data(39 downto 32) & tx_buffer_read_data(47 downto 40) & tx_buffer_read_data(55 downto 48) & tx_buffer_read_data(63 downto 56) & tx_buffer_read_data_R(7 downto 0) & tx_buffer_read_data_R(15 downto 8)                             when SEND_DATA,
		X"000000000000" & tx_buffer_read_data_R(7 downto 0) & tx_buffer_read_data_R(15 downto 8)                                                                                                                                                                                                                                   when SEND_LAST,
		tx_buffer_cpu_read_data(7 downto 0) & tx_buffer_cpu_read_data(15 downto 8) & tx_buffer_cpu_read_data(23 downto 16) & tx_buffer_cpu_read_data(31 downto 24) & tx_buffer_cpu_read_data(39 downto 32) & tx_buffer_cpu_read_data(47 downto 40) & tx_buffer_cpu_read_data(55 downto 48) & tx_buffer_cpu_read_data(63 downto 56) when SEND_CPU_DATA,
		(others => '0')                                                                                                                                                                                                                                                                                                            when others;
-- compute the fixed part of the ip checksum (1's complement logic)
tx_ip_checksum_fixed_0 <= ("00" & X"8412"                                           )+ 
                          ("00" & local_ip(31 downto 16)                            )+ 
                          ("00" & local_ip(15 downto 0)                             );
tx_ip_checksum_fixed_1 <= ("0" & tx_ip_checksum_fixed_0(15 downto 0)                )+
                          ("000000000000000" & tx_ip_checksum_fixed_0(17 downto 16) );
tx_ip_checksum_fixed   <= (tx_ip_checksum_fixed_1(15 downto 0)                      )+
                          ("000000000000000" & tx_ip_checksum_fixed_1(16)           );
-- compute the cpu buffer read address using combinatorial logic to be able to increment it within the cycle where the first data gets acked
tx_buffer_cpu_read_address <= tx_buffer_cpu_read_address_sequential + 1 when (mac_tx_ack = '1' or tx_cpu_got_ack = '1') else tx_buffer_cpu_read_address_sequential;
-- if the address is not part of the subnet (255.255.255.0), then we use the gateway address for the ARP request, otherwise, we use the last bits of the destination address.
tx_arp_cache_address <= local_gateway when tx_addrfifo_read_data(31 downto 8) /= local_ip(31 downto 8) else tx_addrfifo_read_data(7 downto 0);

-- #####   #    #           ####    #####  #####   #
-- #    #   #  #           #    #     #    #    #  #
-- #    #    ##            #          #    #    #  #
-- #####     ##            #          #    #####   #
-- #   #    #  #           #    #     #    #   #   #
-- #    #  #    #           ####      #    #    #  ######

-- receive data buffer
rx_buffer: packet_buffer
	port map (
		clka     => xgmii_clk,
		dina     => rx_buffer_write_data,
		addra    => rx_buffer_write_address_R,
		wea      => rx_buffer_we,
		
		clkb     => clk,
		addrb    => rx_buffer_read_address,
		doutb    => rx_buffer_read_data
	);

---- receive CPU data buffer
rx_buffer_cpu: packet_buffer_cpu
	port map (
		clka     => xgmii_clk,
		dina     => rx_buffer_cpu_write_data,
		addra    => rx_buffer_cpu_write_address_complete,
		wea      => rx_buffer_cpu_we,
		douta    => open,

		clkb     => PLB_Clk,
		dinb     => cpu_rx_buffer_data_in,
		addrb    => cpu_rx_buffer_address,
		web      => cpu_rx_buffer_we,
		doutb    => cpu_rx_buffer_data_out
	);

-- receive address fifos
rx_address_fifo: address_fifo
	port map (
		rst      => rst,

		rd_clk   => clk,
		rd_en    => rx_addrfifo_read_en,
		dout     => rx_addrfifo_read_data,
		valid    => rx_addrfifo_valid,
		
		wr_clk   => xgmii_clk,
		wr_en    => rx_addrfifo_we,
		full     => rx_addrfifo_full,
		din      => rx_addrfifo_write_data
	);

-- read address retimer
rx_read_address_retimer: retimer
	generic map (
		WIDTH     => 11
	)
	port map (
		src_clk       => clk,
		src_data      => rx_buffer_read_address_minusone,
		dest_clk      => xgmii_clk,
		dest_data     => rx_buffer_read_address_minusone_retimed,
		dest_new_data => open
	);

-- *
-- * USER side
-- *

-- receive user clock controller process
rx_user_proc: process(clk)
begin
	if clk'event and clk = '1' then
		if rst = '1' then
			rx_buffer_read_address_sequential <= (others => '0');
		else
			-- increment the read counter
			rx_buffer_read_address_sequential <= rx_buffer_read_address;
		end if;
	end if;
end process;

-- the read address is computed using combinatorial logic to implement first-word-fall-through
rx_valid_ack           <= '1' when rx_ack = '1' and rx_addrfifo_valid = '1' else '0';
rx_buffer_read_address <= rx_buffer_read_address_sequential + ("0000000000" & rx_valid_ack);
-- the data we read from the buffer contains the data going to the user plus the start of frame bit
rx_data                         <= rx_buffer_read_data(63 downto 0);
rx_end_of_frame                 <= rx_buffer_read_data(64);
-- the interface is empty whenever the address fifo is empty
rx_valid                        <= '1' when rx_addrfifo_valid = '1' else '0';

-- we ack data from the address fifo whenever we get a valid end of frame read
rx_addrfifo_read_en             <= '1' when rx_addrfifo_valid = '1' and rx_buffer_read_data(64) = '1' and rx_ack = '1' else '0';
-- we get both address and type from the address fifo
rx_size                         <= rx_addrfifo_read_data(63 downto 48);
rx_source_port                  <= rx_addrfifo_read_data(47 downto 32);
rx_source_ip                    <= rx_addrfifo_read_data(31 downto  0);

-- substracts 1 to the read address before sending it to the retimer
rx_buffer_read_address_minusone <= rx_buffer_read_address - 1;

-- *
-- * MAC side
-- *

-- receive xgmii clock controller process
rx_xgmii_proc: process(xgmii_clk)
begin
	if xgmii_clk'event and xgmii_clk = '1' then
		-- register the data signals coming from the MAC
		mac_rx_data_R       <= mac_rx_data;
		mac_rx_data_valid_R <= mac_rx_data_valid;
		-- register the write buffer address
		rx_buffer_write_address_R <= rx_buffer_write_address;
		-- make sure the fifo write enable is default low
		rx_addrfifo_we <= '0';
		-- state machine		
		if xgmii_rst = '1' then
			rx_state                         <= IDLE;
			rx_buffer_write_address          <= (others => '0');
			rx_buffer_write_address_R        <= (others => '0');
			rx_addrfifo_we                   <= '0';
			rx_cpu_buffer_current            <= '0';
			rx_buffer_cpu_write_address      <= (others => '0');
			rx_cpu_new_buffer                <= '0';
		else
			-- *
			-- * CPU Handshake			
			-- *
			-- 4-way handshake with the PLB interface
			-- if the current buffer is valid and the CPU is done working with its buffer, then we can swap the buffers and tell the CPU
			if rx_cpu_new_buffer = '0' and rx_cpu_buffer_cleared = '0' and rx_cpu_buffer_valid(CONV_INTEGER(rx_cpu_buffer_current)) = '1' then
				rx_cpu_new_buffer         <= '1';
				rx_cpu_buffer_size        <= rx_cpu_buffer_sizes(CONV_INTEGER(rx_cpu_buffer_current));
				rx_cpu_buffer_last        <= rx_cpu_buffer_current;
				rx_cpu_buffer_current     <= not rx_cpu_buffer_current;
			end if;
			-- if the CPU tells us that it is done with the buffer it was processing then we can flag it as unvalid
			if rx_cpu_new_buffer = '1' and rx_cpu_buffer_cleared = '1' then
				rx_cpu_new_buffer         <= '0';
				rx_cpu_buffer_valid(CONV_INTEGER(not rx_cpu_buffer_current)) <= '0';
			end if;
			-- *
			-- * CPU Buffer control state machine			
			-- *
			if mac_rx_data_valid /= "00000000" then
				-- if we reach the ethernet MTU (1500 bytes + 14 bytes header), we stop recording and corrupt the frame
				if rx_buffer_cpu_write_address = X"BE" then
					rx_frame_valid_for_cpu <= '0';					
				else
					-- increment the address counter
					rx_buffer_cpu_write_address <= rx_buffer_cpu_write_address + 1;		
				end if;
				-- if we skipped any data then we corrupt the frame
				if rx_buffer_cpu_we = "0" then
					rx_frame_valid_for_cpu <= '0';
				end if;
			end if;
			if mac_rx_good_frame = '1' and rx_frame_valid_for_cpu = '1' and rx_frame_valid_for_hardware = '0' then
				-- ok, this frame is good, we can flag it as valid
				rx_cpu_buffer_valid(CONV_INTEGER(rx_cpu_buffer_current)) <= '1';
				-- store the size for this buffer, we need to make sure we account for a possible partial word on this cycle
				if mac_rx_data_valid /= "00000000" then
					rx_cpu_buffer_sizes(CONV_INTEGER(rx_cpu_buffer_current)) <= rx_buffer_cpu_write_address + 1;
				else
					rx_cpu_buffer_sizes(CONV_INTEGER(rx_cpu_buffer_current)) <= rx_buffer_cpu_write_address;				
				end if;
			end if;
			if (mac_rx_good_frame = '1' or mac_rx_bad_frame = '1') then
				-- zero the reception address to prepare it for the next frame
				rx_buffer_cpu_write_address <= (others => '0');
			end if;
			-- *
			-- * Hardware Buffer control/depacketization state machine			
			-- *
			case rx_state is
				when IDLE            =>
					-- at first we assume that the frame will be acceptable by both the CPU and the hardware
					rx_frame_valid_for_cpu         <= '1';
					rx_frame_valid_for_hardware    <= '1';
					-- if we receive a valid word from the mac we start a frame reception
					if mac_rx_data_valid = "11111111" then
						rx_state                             <= RECEIVE_HDR_WORD_2;
						-- store the source address
						rx_addrfifo_write_data(47 downto 40) <= mac_rx_data(55 downto 48);
						rx_addrfifo_write_data(39 downto 32) <= mac_rx_data(63 downto 56);
						-- we snapshot the write address to make sure we can rollback to it in case the frame is corrupted
						rx_buffer_write_address_snapshot     <= rx_buffer_write_address;
					end if;
				when RECEIVE_HDR_WORD_2 =>
					-- check that this is an IPv4 frame, with no options or padding
					if (mac_rx_data(39 downto 32) & mac_rx_data(47 downto 40)) /= X"0800" or mac_rx_data(55 downto 48) /= X"45" then
						rx_frame_valid_for_hardware <= '0';
						rx_state                    <= RECEIVE_DATA;
					else
						rx_state                    <= RECEIVE_HDR_WORD_3;
					end if;						
					-- check if the frame has the right destination MAC
					if rx_destination_mac /= local_mac and rx_destination_mac /= X"FFFFFFFFFFFF" then
						rx_frame_valid_for_hardware <= '0';
						rx_frame_valid_for_cpu      <= '0';
						rx_state                    <= RECEIVE_DATA;
					end if;
				when RECEIVE_HDR_WORD_3 =>
					-- check that this is a UDP packet
					if mac_rx_data(63 downto 56) /= X"11" then
						rx_frame_valid_for_hardware <= '0';
						rx_state                    <= RECEIVE_DATA;
					else
						rx_state                    <= RECEIVE_HDR_WORD_4;
					end if;						
				when RECEIVE_HDR_WORD_4 =>
					-- go to the next stage
					rx_state                        <= RECEIVE_HDR_WORD_5;
					-- no IP checksum checking
					-- store the source address
					rx_addrfifo_write_data(31 downto 24) <= mac_rx_data(23 downto 16);
					rx_addrfifo_write_data(23 downto 16) <= mac_rx_data(31 downto 24);					
					rx_addrfifo_write_data(15 downto  8) <= mac_rx_data(39 downto 32);
					rx_addrfifo_write_data( 7 downto  0) <= mac_rx_data(47 downto 40);					
				when RECEIVE_HDR_WORD_5 =>
					-- go to the next stage
					rx_state                        <= RECEIVE_HDR_WORD_6;
					-- store the source port
					rx_addrfifo_write_data(47 downto 40) <= mac_rx_data(23 downto 16);
					rx_addrfifo_write_data(39 downto 32) <= mac_rx_data(31 downto 24);
					-- store the size (minus 8 to get the payload only size)
					rx_addrfifo_write_data(63 downto 48) <= (mac_rx_data(55 downto 48) & mac_rx_data(63 downto 56)) - 8;
					-- check the destination port
					if rx_destination_port /= local_port then
						rx_frame_valid_for_hardware <= '0';
						rx_state                    <= RECEIVE_DATA;						
					end if;
					-- check the destination IP
					if rx_destination_ip /= local_ip then
						rx_frame_valid_for_hardware <= '0';
						rx_state                    <= RECEIVE_DATA;
					end if;
				when RECEIVE_HDR_WORD_6 =>
					-- go to the next stage
					rx_state           <= RECEIVE_DATA;
					-- no UDP checksum checking
					-- increment the buffer address
					if rx_buffer_full = '0' then
						rx_buffer_write_address  <= rx_buffer_write_address + 1;
					end if;
				when RECEIVE_DATA =>
					if mac_rx_good_frame = '1' then
						if rx_frame_valid_for_hardware = '1' and rx_buffer_full = '0' and rx_addrfifo_full = '0' then
							-- write the address and the protocol in the address fifo
							rx_addrfifo_we            <= '1';
							rx_state                  <= IDLE;
						else
							-- rollback the buffer address and go back to idle
							rx_buffer_write_address   <= rx_buffer_write_address_snapshot;
							rx_buffer_write_address_R <= rx_buffer_write_address_snapshot;
							rx_state                  <= IDLE;
						end if;
					end if;
					if mac_rx_bad_frame = '1' then
						-- rollback the buffer address and go back to idle
						rx_buffer_write_address   <= rx_buffer_write_address_snapshot;
						rx_buffer_write_address_R <= rx_buffer_write_address_snapshot;
						rx_state                  <= IDLE;
					end if;
					if mac_rx_data_valid(2) = '1' and rx_buffer_full = '0' then
						-- increment the write address
						rx_buffer_write_address  <= rx_buffer_write_address + 1;
					end if;
			end case;
			-- if the buffer gets full at any time or the local parameters become invalid then we corrupt the frame
			if rx_buffer_full = '1' or local_valid_retimed = '0' then
				rx_frame_valid_for_hardware <= '0';
			end if;
		end if;
	end if;
end process;


-- data to be written in the buffer
rx_buffer_write_data(64)           <= '1' when mac_rx_data_valid(2) = '0' else '0';
rx_buffer_write_data(63 downto 56) <= mac_rx_data_R(23 downto 16) when mac_rx_data_valid_R(2) = '1' else X"00";
rx_buffer_write_data(55 downto 48) <= mac_rx_data_R(31 downto 24) when mac_rx_data_valid_R(3) = '1' else X"00";
rx_buffer_write_data(47 downto 40) <= mac_rx_data_R(39 downto 32) when mac_rx_data_valid_R(4) = '1' else X"00";
rx_buffer_write_data(39 downto 32) <= mac_rx_data_R(47 downto 40) when mac_rx_data_valid_R(5) = '1' else X"00";
rx_buffer_write_data(31 downto 24) <= mac_rx_data_R(55 downto 48) when mac_rx_data_valid_R(6) = '1' else X"00";
rx_buffer_write_data(23 downto 16) <= mac_rx_data_R(63 downto 56) when mac_rx_data_valid_R(7) = '1' else X"00";
rx_buffer_write_data(15 downto  8) <= mac_rx_data( 7 downto  0)   when mac_rx_data_valid(0)   = '1' else X"00";
rx_buffer_write_data( 7 downto  0) <= mac_rx_data(15 downto  8)   when mac_rx_data_valid(1)   = '1' else X"00";
-- data to be written in the cpu buffer
rx_buffer_cpu_write_data           <= mac_rx_data(7 downto 0) & mac_rx_data(15 downto 8) & mac_rx_data(23 downto 16) & mac_rx_data(31 downto 24) & mac_rx_data(39 downto 32) & mac_rx_data(47 downto 40) & mac_rx_data(55 downto 48) & mac_rx_data(63 downto 56);
-- if the current buffer is already valid, we disable writing to make sure we don't overwrite anything
rx_buffer_cpu_we                   <= "1" when rx_cpu_buffer_valid(CONV_INTEGER(rx_cpu_buffer_current)) = '0' else "0";
-- the receive buffers can always be written as the write address always points to an empty slot
rx_buffer_we                       <= "1";
-- the receive buffer is full whenever the write address is right behind the read address
rx_buffer_full                     <= '1' when rx_buffer_write_address     = rx_buffer_read_address_minusone_retimed     else '0';
-- destination addresses
rx_destination_mac                 <= mac_rx_data_R( 7 downto  0) & mac_rx_data_R(15 downto  8) & mac_rx_data_R(23 downto 16) & mac_rx_data_R(31 downto 24) & mac_rx_data_R(39 downto 32) & mac_rx_data_R(47 downto 40);
rx_destination_ip                  <= mac_rx_data_R(55 downto 48) & mac_rx_data_R(63 downto 56) & mac_rx_data  ( 7 downto  0) & mac_rx_data  (15 downto  8) ;
rx_destination_port                <= mac_rx_data(39 downto 32) & mac_rx_data(47 downto 40);
-- complete cpu buffer address with buffer selection
rx_buffer_cpu_write_address_complete <= rx_cpu_buffer_current & rx_buffer_cpu_write_address;

-- unused and constant signals
-- we don't gather any statistics on the MAC
	-- mac_rx_statistics_vector
	-- mac_rx_statistics_valid


--  ####   #####   #    #
-- #    #  #    #  #    #
-- #       #    #  #    #
-- #       #####   #    #
-- #    #  #       #    #
--  ####   #        ####

-- cpu interface
-- retime/delay signals between the cpu clock and the xgmii clock
cpu_xgmii_retime_proc: process(xgmii_clk)
begin
	if xgmii_clk'event and xgmii_clk = '1' then
		-- To spare ressources, we only retime the valid signal, and not the other parameters signals.
		-- The software is responsible for making sure that local_valid is deasserted when parameters are updated
		local_valid_retimed        <= local_valid;
		-- rx CPU handshake
		-- we add two stages of delay on the synchronization signal to prevent incorrect sampling of the size and the buffer select bits
		rx_cpu_buffer_cleared_pre  <= cpu_rx_cpu_buffer_cleared;
		rx_cpu_buffer_cleared      <= rx_cpu_buffer_cleared_pre;
		-- tx CPU handshake
		-- we add two stages of delay on the synchronization signal to prevent incorrect sampling of the size and the buffer select bits
		tx_cpu_buffer_filled_pre   <= cpu_tx_cpu_buffer_filled;
		tx_cpu_buffer_filled       <= tx_cpu_buffer_filled_pre;

	end if;
end process;
-- retime/delay signals between the xgmii clock and the cpu clock
xgmii_cpu_retime_proc: process(PLB_Clk)
begin
	if PLB_Clk'event and PLB_Clk = '1' then
		-- rx cpu handshake
		-- we add two stages of delay on the synchronization signal to prevent incorrect sampling of the size and the buffer select bits
		cpu_rx_cpu_new_buffer_pre  <= rx_cpu_new_buffer;
		cpu_rx_cpu_new_buffer      <= cpu_rx_cpu_new_buffer_pre;
		-- tx cpu handshake
		-- we add two stages of delay on the synchronization signal to prevent incorrect sampling of the size and the buffer select bits
		cpu_tx_cpu_free_buffer_pre <= tx_cpu_free_buffer;
		cpu_tx_cpu_free_buffer     <= cpu_tx_cpu_free_buffer_pre;
	end if;
end process;

-- the sizes and buffer select bits are transmitted with no delay to allow them to stabilize before they are resample by the PLB attachment
cpu_rx_cpu_buffer_size          <= rx_cpu_buffer_size;
cpu_rx_cpu_buffer_select        <= rx_cpu_buffer_last;
tx_cpu_buffer_size              <= cpu_tx_cpu_buffer_size;
cpu_tx_cpu_buffer_select        <= tx_cpu_buffer_next;


-- plb attachment
plb : plb_attach
	generic map (
		C_BASEADDR            => C_BASEADDR             ,
		C_HIGHADDR            => C_HIGHADDR             ,
		C_PLB_AWIDTH          => C_PLB_AWIDTH           ,
		C_PLB_DWIDTH          => C_PLB_DWIDTH           ,
		C_PLB_NUM_MASTERS     => C_PLB_NUM_MASTERS      ,
		C_PLB_MID_WIDTH       => C_PLB_MID_WIDTH        ,
		C_FAMILY              => C_FAMILY         
	)
	port map (
		-- local configuration
		local_mac             => local_mac              ,
		local_ip              => local_ip               ,
		local_gateway         => local_gateway          ,
		local_port            => local_port             ,
		local_valid           => local_valid            ,

		-- tx buffer
		tx_buffer_data_in     => cpu_tx_buffer_data_in  ,
		tx_buffer_address     => cpu_tx_buffer_address  ,
		tx_buffer_we          => cpu_tx_buffer_we(0)    ,
		tx_buffer_data_out    => cpu_tx_buffer_data_out ,
		tx_cpu_buffer_size    => cpu_tx_cpu_buffer_size ,
		tx_cpu_free_buffer    => cpu_tx_cpu_free_buffer ,
		tx_cpu_buffer_filled  => cpu_tx_cpu_buffer_filled,
		tx_cpu_buffer_select  => cpu_tx_cpu_buffer_select,

		-- rx buffer
		rx_buffer_data_in     => cpu_rx_buffer_data_in  ,
		rx_buffer_address     => cpu_rx_buffer_address  ,
		rx_buffer_we          => cpu_rx_buffer_we(0)    ,
		rx_buffer_data_out    => cpu_rx_buffer_data_out ,
		rx_cpu_buffer_size    => cpu_rx_cpu_buffer_size ,
		rx_cpu_new_buffer     => cpu_rx_cpu_new_buffer  ,
		rx_cpu_buffer_cleared => cpu_rx_cpu_buffer_cleared ,
		rx_cpu_buffer_select  => cpu_rx_cpu_buffer_select,

		-- ARP cache
		arp_cache_data_in     => cpu_arp_cache_data_in  ,
		arp_cache_address     => cpu_arp_cache_address  ,
		arp_cache_we          => cpu_arp_cache_we(0)    ,
		arp_cache_data_out    => cpu_arp_cache_data_out ,
		
		-- PLB attachment
		PLB_Clk               => PLB_Clk                ,
		PLB_Rst               => PLB_Rst                ,
		Sl_addrAck            => Sl_addrAck             ,
		Sl_MBusy              => Sl_MBusy               ,
		Sl_MErr               => Sl_MErr                ,
		Sl_rdBTerm            => Sl_rdBTerm             ,
		Sl_rdComp             => Sl_rdComp              ,
		Sl_rdDAck             => Sl_rdDAck              ,
		Sl_rdDBus             => Sl_rdDBus              ,
		Sl_rdWdAddr           => Sl_rdWdAddr            ,
		Sl_rearbitrate        => Sl_rearbitrate         ,
		Sl_SSize              => Sl_SSize               ,
		Sl_wait               => Sl_wait                ,
		Sl_wrBTerm            => Sl_wrBTerm             ,
		Sl_wrComp             => Sl_wrComp              ,
		Sl_wrDAck             => Sl_wrDAck              ,
		PLB_abort             => PLB_abort              ,
		PLB_ABus              => PLB_ABus               ,
		PLB_BE                => PLB_BE                 ,
		PLB_busLock           => PLB_busLock            ,
		PLB_compress          => PLB_compress           ,
		PLB_guarded           => PLB_guarded            ,
		PLB_lockErr           => PLB_lockErr            ,
		PLB_masterID          => PLB_masterID           ,
		PLB_MSize             => PLB_MSize              ,
		PLB_ordered           => PLB_ordered            ,
		PLB_PAValid           => PLB_PAValid            ,
		PLB_pendPri           => PLB_pendPri            ,
		PLB_pendReq           => PLB_pendReq            ,
		PLB_rdBurst           => PLB_rdBurst            ,
		PLB_rdPrim            => PLB_rdPrim             ,
		PLB_reqPri            => PLB_reqPri             ,
		PLB_RNW               => PLB_RNW                ,
		PLB_SAValid           => PLB_SAValid            ,
		PLB_size              => PLB_size               ,
		PLB_type              => PLB_type               ,
		PLB_wrBurst           => PLB_wrBurst            ,
		PLB_wrDBus            => PLB_wrDBus             ,
		PLB_wrPrim            => PLB_wrPrim       
	);


-- #       ######  #####    ####
-- #       #       #    #  #
-- #       #####   #    #   ####
-- #       #       #    #       #
-- #       #       #    #  #    #
-- ######  ######  #####    ####

-- extends LEDs light-up on transmit and receive events, and register LED signals
led_proc: process(xgmii_clk)
begin
	if xgmii_clk'event and xgmii_clk = '1' then
		-- register led outputs to help timing closure
		led_up <= phy_rx_up;
		led_rx <= led_rx_1;
		led_tx <= led_tx_1;
		-- extend rx LED pulses
		if led_rx_count = X"200000" then
			led_rx_1 <= '0';
		else
			led_rx_count <= led_rx_count + 1;
		end if;
		if mac_rx_good_frame = '1' then
			led_rx_1     <= '1';
			led_rx_count <= (others => '0');
		end if;
		-- extend tx LED pulses
		if led_tx_count = X"200000" then
			led_tx_1 <= '0';
		else
			led_tx_count <= led_tx_count + 1;
		end if;
		if mac_tx_ack = '1' then
			led_tx_1     <= '1';
			led_tx_count <= (others => '0');
		end if;
	end if;
end process;

-- #    #    ##     ####
-- ##  ##   #  #   #    #
-- # ## #  #    #  #
-- #    #  ######  #
-- #    #  #    #  #    #
-- #    #  #    #   ####

-- configuration vector
mac_configuration_vector <=
	'0'           & -- Discard preamble when receiving frames
	'0'           & -- Use 802.3 standard preamble when transmitting frames
	'0'           & -- Allow transmission/reception of ordered fault sets to deal with link resynchronization in case of a link down event
	'0'           & -- Reserved, must be 0
	'0'           & -- Do not resize inter-frame gap, use aligned start
	'0'           & -- Do not send any flow control frame
	'0'           & -- Listen to flow control and stop operation when receiving a pause frame
	'0'           & -- No transmitter reset
	'1'           & -- Allow transmission of jumbo-frames
	'0'           & -- Checksum computed and added to the frame by the MAC
	'1'           & -- Enable transmitter
	'0'           & -- VLAN transmission disabled
	'0'           & -- Use minimum interframe gap
	'0'           & -- Do not use WAN rate emulation
	'0'           & -- No receiver reset
	'1'           & -- Allow reception of jumbo-frames
	'0'           & -- Checksum verified by the MAC
	'1'           & -- Enable the receiver
	'0'           & -- VLAN reception disabled
	local_mac;    -- mac address to use for flow control frames

-- flow control (disabled)
mac_flow_pause_val   <= (others => '0');
mac_flow_pause_req   <= '0';

-- unused and constant signals
-- we don't use underrun capability of the MAC because we can ensure that the packet is in the buffer before we start sending it
mac_tx_underrun      <= '0';
-- we use minimum interframe gap and don't need to indicate any delay to the MAC
mac_tx_ifg_delay     <= (others => '0');
-- we don't gather any statistics on the MAC
	-- mac_tx_statistics_vector
	-- mac_tx_statistics_valid

XILINX_MAC: if USE_XILINX_MAC = 1 generate
	-- 10 Gb Ethernet MAC -- Xilinx MAC
	mac : ten_gig_eth_mac_v8_0
		port map (
			-- reset
			reset                 => rst,
			-- clocks
			tx_clk0               => xgmii_clk,
			tx_dcm_lock           => '1',
			rx_clk0               => xgmii_clk,
			rx_dcm_lock           => '1',
			-- transmit interface
			tx_underrun           => mac_tx_underrun          ,
			tx_data               => mac_tx_data              ,
			tx_data_valid         => mac_tx_data_valid        ,
			tx_start              => mac_tx_start             ,
			tx_ack                => mac_tx_ack               ,
			tx_ifg_delay          => mac_tx_ifg_delay         ,
			tx_statistics_vector  => mac_tx_statistics_vector ,
			tx_statistics_valid   => mac_tx_statistics_valid  ,
			-- receive interface
			rx_data               => mac_rx_data              ,
			rx_data_valid         => mac_rx_data_valid        ,
			rx_good_frame         => mac_rx_good_frame        ,
			rx_bad_frame          => mac_rx_bad_frame         ,
			rx_statistics_vector  => mac_rx_statistics_vector ,
			rx_statistics_valid   => mac_rx_statistics_valid  ,
			-- flow_control interface
			pause_val             => mac_flow_pause_val       ,
			pause_req             => mac_flow_pause_req       ,
			-- configuraion
			configuration_vector  => mac_configuration_vector ,
			-- phy interface
			xgmii_txd             => xgmii_tx_data,
			xgmii_txc             => xgmii_tx_ctrl,
			xgmii_rxd             => xgmii_rx_data,
			xgmii_rxc             => xgmii_rx_ctrl
		);
end generate;

UCB_MAC: if USE_UCB_MAC = 1 generate
	-- 10 Gb Ethernet MAC -- UCB MAC
	mac : ten_gig_eth_mac_UCB
		port map (
			-- reset
			reset                 => rst,
			-- clocks
			tx_clk0               => xgmii_clk,
			tx_dcm_lock           => '1',
			rx_clk0               => xgmii_clk,
			rx_dcm_lock           => '1',
			-- transmit interface
			tx_underrun           => mac_tx_underrun          ,
			tx_data               => mac_tx_data              ,
			tx_data_valid         => mac_tx_data_valid        ,
			tx_start              => mac_tx_start             ,
			tx_ack                => mac_tx_ack               ,
			tx_ifg_delay          => mac_tx_ifg_delay         ,
			tx_statistics_vector  => mac_tx_statistics_vector ,
			tx_statistics_valid   => mac_tx_statistics_valid  ,
			-- receive interface
			rx_data               => mac_rx_data              ,
			rx_data_valid         => mac_rx_data_valid        ,
			rx_good_frame         => mac_rx_good_frame        ,
			rx_bad_frame          => mac_rx_bad_frame         ,
			rx_statistics_vector  => mac_rx_statistics_vector ,
			rx_statistics_valid   => mac_rx_statistics_valid  ,
			-- flow_control interface
			pause_val             => mac_flow_pause_val       ,
			pause_req             => mac_flow_pause_req       ,
			-- configuraion
			configuration_vector  => mac_configuration_vector ,
			-- phy interface
			xgmii_txd             => xgmii_tx_data,
			xgmii_txc             => xgmii_tx_ctrl,
			xgmii_rxd             => xgmii_rx_data,
			xgmii_rxc             => xgmii_rx_ctrl
		);
end generate;

-- #####   #    #   #   #
-- #    #  #    #    # #
-- #    #  ######     #
-- #####   #    #     #
-- #       #    #     #
-- #       #    #     #

-- configuration vector
phy_configuration_vector <=
	"00"       & -- test pattern
	'0'        & -- No test mode
	xgmii_rst  & -- Reset RX link status on reset
	xgmii_rst  & -- Reset fault latch status on reset
	'0'        & -- No power down
	'0';         -- No loopback

-- status_vector
phy_rx_up <= phy_status_vector(6);

-- 10 Gb Ethernet PHY (XAUI)
phy : xaui_v6_2
	port map (
		-- reset
		reset                 => rst,
		-- clock
		usrclk                => xgmii_clk,
		-- data
		xgmii_txd             => xgmii_tx_data,
		xgmii_txc             => xgmii_tx_ctrl,
		xgmii_rxd             => xgmii_rx_data,
		xgmii_rxc             => xgmii_rx_ctrl,
		-- status and configuration
		signal_detect         => "1111",
		align_status          => open,
		sync_status           => open,
		configuration_vector  => phy_configuration_vector,
		status_vector         => phy_status_vector,
		-- link to the MGTs
		mgt_txdata            => mgt_txdata,
		mgt_txcharisk         => mgt_txcharisk,
		mgt_rxdata            => mgt_rxdata,
		mgt_rxcharisk         => mgt_rxcharisk,
		mgt_codevalid         => mgt_codevalid,
		mgt_codecomma         => mgt_codecomma,
		mgt_enable_align      => mgt_enable_align,
		mgt_enchansync        => mgt_enchansync,
		mgt_syncok            => mgt_syncok,
		mgt_loopback          => mgt_loopback,
		mgt_powerdown         => mgt_powerdown,
		mgt_tx_reset          => mgt_tx_reset,
		mgt_rx_reset          => mgt_rx_reset
	);

-- #    #   ####    #####   ####
-- ##  ##  #    #     #    #
-- # ## #  #          #     ####
-- #    #  #  ###     #         #
-- #    #  #    #     #    #    #
-- #    #   ####      #     ####

-- transceiver 0
transceiver0 : transceiver
	generic map (
		CHBONDMODE => "MASTER" ,
		CONNECTOR  => CONNECTOR,
		CHANNEL    => 0,
		PREEMPHASYS=> PREEMPHASYS,
		SWING      => SWING
	)
	port map (
		reset        => rst,
		clk          => xgmii_clk,
		brefclk      => mgt_brefclk,
		brefclk2     => mgt_brefclk2,
		refclksel    => speed_select,
		dcm_locked   => '1',
		txdata       => mgt_txdata(15 downto 0),
		txcharisk    => mgt_txcharisk(1 downto 0),
		txp          => mgt_tx_l0_p,
		txn          => mgt_tx_l0_n,
		rxdata       => mgt_rxdata(15 downto 0),
		rxcharisk    => mgt_rxcharisk(1 downto 0),
		rxp          => mgt_rx_l0_p,
		rxn          => mgt_rx_l0_n,
		enable_align => mgt_enable_align(0),
		syncok       => mgt_syncok(0),
		enchansync   => mgt_enchansync,
		code_valid   => mgt_codevalid(1 downto 0),
		code_comma   => mgt_codecomma(1 downto 0),
		loopback_ser => mgt_loopback,
		powerdown    => mgt_powerdown,
		chbondi      => "XXXX",
		chbondo      => mgt_chbond,
		mgt_tx_reset => mgt_tx_reset(0),
		mgt_rx_reset => mgt_rx_reset(0)
	);

-- transceiver 1
transceiver1 : transceiver
	generic map (
		CHBONDMODE => "SLAVE_1_HOP",
		CONNECTOR  => CONNECTOR    ,
		CHANNEL    => 1,
		PREEMPHASYS=> PREEMPHASYS,
		SWING      => SWING
	)          
	port map (
		reset        => rst,
		clk          => xgmii_clk,
		brefclk      => mgt_brefclk,  
		brefclk2     => mgt_brefclk2, 
		refclksel    => speed_select,
		dcm_locked   => '1',
		txdata       => mgt_txdata(31 downto 16),
		txcharisk    => mgt_txcharisk(3 downto 2),
		txp          => mgt_tx_l1_p,
		txn          => mgt_tx_l1_n,
		rxdata       => mgt_rxdata(31 downto 16),
		rxcharisk    => mgt_rxcharisk(3 downto 2),
		rxp          => mgt_rx_l1_p,
		rxn          => mgt_rx_l1_n,
		enable_align => mgt_enable_align(1),
		syncok       => mgt_syncok(1),
		enchansync   => '1',
		code_valid   => mgt_codevalid(3 downto 2),
		code_comma   => mgt_codecomma(3 downto 2),
		loopback_ser => mgt_loopback,
		powerdown    => mgt_powerdown,
		chbondi      => mgt_chbond,
		chbondo      => open,
		mgt_tx_reset => mgt_tx_reset(1),
		mgt_rx_reset => mgt_rx_reset(1)
	);

-- transceiver 2
transceiver2 : transceiver
	generic map (
		CHBONDMODE => "SLAVE_1_HOP",
		CONNECTOR  => CONNECTOR    ,
		CHANNEL    => 2,
		PREEMPHASYS=> PREEMPHASYS,
		SWING      => SWING
	)
	port map (
		reset        => rst,
		clk          => xgmii_clk,
		brefclk      => mgt_brefclk,  
		brefclk2     => mgt_brefclk2, 
		refclksel    => speed_select,
		dcm_locked   => '1',
		txdata       => mgt_txdata(47 downto 32),
		txcharisk    => mgt_txcharisk(5 downto 4),
		txp          => mgt_tx_l2_p,
		txn          => mgt_tx_l2_n,
		rxdata       => mgt_rxdata(47 downto 32),
		rxcharisk    => mgt_rxcharisk(5 downto 4),
		rxp          => mgt_rx_l2_p,
		rxn          => mgt_rx_l2_n,
		enable_align => mgt_enable_align(2),
		syncok       => mgt_syncok(2),
		enchansync   => '1',
		code_valid   => mgt_codevalid(5 downto 4),
		code_comma   => mgt_codecomma(5 downto 4),
		loopback_ser => mgt_loopback,
		powerdown    => mgt_powerdown,
		chbondi      => mgt_chbond,
		chbondo      => open,
		mgt_tx_reset => mgt_tx_reset(2),
		mgt_rx_reset => mgt_rx_reset(2)
	);

-- transceiver 3
transceiver3 : transceiver
	generic map (
		CHBONDMODE => "SLAVE_1_HOP",
		CONNECTOR  => CONNECTOR    ,
		CHANNEL    => 3,
		PREEMPHASYS=> PREEMPHASYS,
		SWING      => SWING
	)
	port map (
		reset        => rst,
		clk          => xgmii_clk,
		brefclk      => mgt_brefclk,  
		brefclk2     => mgt_brefclk2, 
		refclksel    => speed_select,
		dcm_locked   => '1',
		txdata       => mgt_txdata(63 downto 48),
		txcharisk    => mgt_txcharisk(7 downto 6),
		txp          => mgt_tx_l3_p,
		txn          => mgt_tx_l3_n,
		rxdata       => mgt_rxdata(63 downto 48),
		rxcharisk    => mgt_rxcharisk(7 downto 6),
		rxp          => mgt_rx_l3_p,
		rxn          => mgt_rx_l3_n,
		enable_align => mgt_enable_align(3),
		syncok       => mgt_syncok(3),
		enchansync   => '1',
		code_valid   => mgt_codevalid(7 downto 6),
		code_comma   => mgt_codecomma(7 downto 6),
		loopback_ser => mgt_loopback,
		powerdown    => mgt_powerdown,
		chbondi      => mgt_chbond,
		chbondo      => open,
		mgt_tx_reset => mgt_tx_reset(3),
		mgt_rx_reset => mgt_rx_reset(3)
	);

end architecture ten_gb_eth_arch;
