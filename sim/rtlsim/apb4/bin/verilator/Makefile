#####################################################################
##   ,------.                    ,--.                ,--.          ##
##   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    ##
##   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    ##
##   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    ##
##   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    ##
##                                             `---'               ##
##   Verilator Makefile                                            ##
##                                                                 ##
#####################################################################
##                                                                 ##
##             Copyright (C) 2023 ROA Logic BV                     ##
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

#################################################################
# Make Targets
#################################################################
.PHONY: sim simw clean

LOG = log/$(TOP).log

#Object directory, design is verilated here
OBJDIR=obj_dir

#Set VERILATOR_ROOT if not already set
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V | grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
VERILATOR_FLAGS ?= -Wall -Wno-PINCONNECTEMPTY 
VERILATE_FLAGS ?= -CFLAGS -DVL_NO_LEGACY $(VERILATOR_FLAGS) -structs-packed --timing

#These files need to be included in the compile
VERILATOR_CXX     = $(addprefix $(VERILATOR_ROOT)/include/, verilated_threads.cpp verilated.cpp)
VERILATOR_INCLUDE = $(addprefix -I, $(VERILATOR_ROOT)/include $(VERILATOR_ROOT)/include/vltstd)

INCLUDE = $(addprefix -I, $(TB_SRC_DIR)/verilator/verilator-simulation/testbench)
#$(TB_SRC_DIR)/verilator/verilator-simulation/testbench

#CXX Variables
CXX ?= g++
CXXFLAGS ?= 
CPPSTD ?= c++11
#CPPLIB ?= libc++
#CPPLIB ?= libstdc++

LDLIBS = -lm

ifdef PLI
ifneq ($(PLI),"")
  PLI_OPTS = -pli $(PLI)
endif
endif


sim: $(OBJDIR)/V$(RTL_TOP)__ALL.o $(PLI)
	echo "--- Building $(TOP)"
	$(CXX) $(CXXFLAGS) -std=$(CPPSTD) \
	$(VERILATOR_INCLUDE) $(VERILATOR_CXX) \
	-I./$(OBJDIR) $(INCLUDE) $^ $(TB_CXX) \
	$(addprefix -I, $(TB_CXX_INCL))       \
	$(LDFLAGS) $(LDLIBS)					\
	-o $(TOP)


simw: verilate $(PLI)
	echo "--- Running sim"
	vsim $(SIM_OPTS) $(PLI_OPTS)			\
	 -l $(LOG) $(TOP) 				\
	 +access +r -wlf $(LOG).wlf			\
	$(foreach p, $(PARAMS),-g`echo $p | sed -r 's/(\w+)=([^0-9].*)/\1="\2"/'`)


lint: $(VLOG)
	@echo "--- Running Lint $(TOP)"
	verilator $(VERILATOR_FLAGS) --lint-only --top-module $(TOP) $(VLOG) > $(TOP).lint.log 2>&1 
	@echo "--- Done, see $(TOP).lint.log"

clean:
	@rm -rf $(OBJDIR) log



#################################################################
## VHDL
#################################################################


#################################################################
## Verilator
#################################################################

.PHONY: $(VLOG)

$(OBJDIR)/V%.mk: $(OBJDIR) $(VLOG)
	echo "--- Verilating $*"
	verilator $(VERILATOR_FLAGS) $(VERILATE_FLAGS)		\
	-Mdir $(@D) --cc $(VLOG) --top-module $*		\
	$(foreach d,$(DEFINES),+define+$d)			\
	$(foreach d,$(INCDIRS),+incdir+$d)			\
	$(foreach l,$(wildcard $(LIBDIRS)),-y $l)
#+libext$(foreach e,$(LIBEXT),+$e)


%__ALL.o: %.mk 
	echo "--- Building $(@F)"
	make -C $(@D) -f $(^F)


#################################################################
## PLI
#################################################################

#%.o : %.c
#	echo "--- Compiling $@"
#	$(CC) -c -m32 -fPIC -I `which vsim | sed -r 's/(.*modeltech).*/\1\/include/'` $< -o $@


ifeq ($(JTAG_DBG), VPI)
  PLI_OBJ = $(basename $(PLI)).o
else ifeq ($(JTAG_DBG), OPENOCD)
  PLI_OBJ = $(basename $(PLI)).o $(dir $(PLI))jtag_common.o
else
endif

$(PLI): $(PLI_OBJ)
	echo "--- linking JTAG-VPI $@"
	$(LD) -shared -m elf_i386 -fPIC -G -o $@ $?


#################################################################
## Directories
#################################################################
$(OBJDIR):
	mkdir -p $@ log
