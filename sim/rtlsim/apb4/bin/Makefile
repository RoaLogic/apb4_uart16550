#####################################################################
##   ,------.                    ,--.                ,--.          ##
##   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    ##
##   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    ##
##   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    ##
##   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    ##
##                                             `---'               ##
##   APB UART16550 Test Makefile                                   ##
##                                                                 ##
#####################################################################
##                                                                 ##
##             Copyright (C) 2016-2021 ROA Logic BV                ##
##             www.roalogic.com                                    ##
##                                                                 ##
##   This source file may be used and distributed without          ##
##   restriction provided that this copyright statement is not     ##
##   removed from the file and that any derivative work contains   ##
##   the original copyright notice and the associated disclaimer.  ##
##                                                                 ##
##      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        ##
##   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     ##
##   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     ##
##   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR OR     ##
##   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  ##
##   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  ##
##   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  ##
##   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      ##
##   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     ##
##   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  ##
##   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS          ##
##   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  ##
##                                                                 ##
#####################################################################


all: sim

SIMULATORS = msim ncsim vcs riviera verilator
LINTERS    = $(addsuffix _lint, $(SIMULATORS))
SIMWAVES   = $(addsuffix _waves, $(SIMULATORS))
SIMGATES   = $(addsuffix _gate, $(SIMULATORS))
SIMULATOR  = verilator


all:  sim
sim:  $(SIMULATOR)
simw: $(SIMULATOR)_waves
lint: $(SIMULATOR)_lint

MS     = -s

ROOT_DIR=../../../..


##########################################################################
#
# Sources
#
##########################################################################
-include Makefile.include


##########################################################################
#
# libraries
#
##########################################################################
RTL_LIBS =


##########################################################################
#
# Misc Variables
#
##########################################################################
INCDIRS:=$(INCDIRS)
DEFINES:=$(DEFINES)

shell=/bin/sh


##########################################################################
#
# OVL
#
##########################################################################
ifeq ($(OVL_ASSERT),ON)
    INCDIRS+=$(STD_OVL_DIR) $(INCDIRS)
    DEFINES+=OVL_ASSERT_ON $(DEFINES)
    LIBDIRS+=$(STD_OVL_DIR)
    LIBEXT +=.vlib

    ifeq ($(OVL_INIT_MSG),ON)
        DEFINES:=OVL_INIT_MSG $(DEFINES)
    endif
endif


##########################################################################
#
# Make Targets
#
##########################################################################
.PHONY: $(SIMULATORS) $(LINTERS) $(SIMWAVES)


$(SIMULATORS): % : %/Makefile $(TB_PREREQ)
	@$(MAKE) $(MS) -C $@ sim				\
	VLOG="$(abspath $(RTL_VLOG) $(TB_VLOG))"		\
	TB_CXX="$(abspath $(TB_CXX))"				\
	TB_CXX_INCL="$(abspath $(TB_CXX_INCL))"			\
	TECHLIBS="$(TECHLIBS)"					\
	LIBDIRS="$(LIBDIRS)"					\
	LIBEXT="$(LIBEXT)"					\
	PLI=$(TB_PLI)						\
	VHDL="$(abspath $(RTL_VHDL) $(TB_VHDL))"		\
	INCDIRS="$(abspath $(INCDIRS))"				\
	DEFINES="$(DEFINES)"					\
	RTL_TOP=$(RTL_TOP)					\
	TOP=$(TB_TOP)						\
	LOG=$(LOG) PARAMS="$(PARAMS)"				\
	JTAG_DBG=$(JTAG_DBG)


$(SIMWAVES): %_waves : %/Makefile $(TB_PREREQ)
	$(MAKE) $(MS) -C $(subst _waves,,$@) simw		\
	VLOG="$(abspath $(RTL_VLOG) $(TB_VLOG))"		\
	TB_CPP="$(TB_CPP)"					\
	TECHLIBS="$(TECHLIBS)"					\
	LIBDIRS="$(LIBDIRS)"					\
	LIBEXT="$(LIBEXT)"					\
	PLI=$(TB_PLI)						\
	VHDL="$(abspath $(RTL_VHDL) $(TB_VHDL))"		\
	INCDIRS="$(abspath $(INCDIRS))"				\
	DEFINES="$(DEFINES)"					\
	TOP=$(TB_TOP)						\
	LOG=$(LOG) PARAMS="$(PARAMS)"				\
	JTAG_DBG=$(JTAG_DBG)


$(SIMGATES): %_gate : %/Makefile $(TB_PREREQ)
	$(MAKE) $(MS) -C $(subst _gate,,$@) simgate		\
	VLOG="$(abspath $(GATE_VLOG) $(TB_VLOG))"		\
	SDF="$(abspath $(GATE_SDF))"				\
	TECHLIBS="$(TECHLIBS)"					\
	LIBDIRS="$(LIBDIRS)"					\
	LIBEXT="$(LIBEXT)"					\
	PLI=$(TB_PLI)						\
	INCDIRS="$(abspath $(INCDIRS))"				\
	DEFINES="$(DEFINES)"					\
	TOP=$(TB_TOP)						\
	LOG=$(LOG) PARAMS="$(PARAMS)"				\
	JTAG_DBG=$(JTAG_DBG)


$(LINTERS): %_lint : %/Makefile $(TB_PREREQ)
	@$(MAKE) $(MS) -C $(subst _lint,,$@) lint		\
	VLOG="$(abspath $(RTL_VLOG))"				\
	VHDL="$(abspath $(RTL_VHDL))"				\
	INCDIRS="$(abspath $(INCDIRS))"				\
	DEFINES="$(DEFINES)"					\
	TOP=$(RTL_TOP)


.PHONY: clean distclean mrproper
clean:
	@for f in $(wildcard *); do				\
		if test -d $$f; then $(MAKE) -C $$f clean; fi	\
	done


distclean:
	@rm -rf $(SIMULATORS) Makefile.include $(TB_PREREQ)


mrproper:
	@rm -rf *


##########################################################################
#
# Make simulation structure
#
##########################################################################
Makefile.include:
	@cp ../bin/Makefile.include .


%/Makefile:
	@mkdir -p $*
	@cp ../bin/sims/Makefile.$* $@


$(TB_PREREQ):
	@cp ../bin/$@ $@
