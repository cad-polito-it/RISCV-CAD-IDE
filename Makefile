# Costanti

MAKE 			= make 
MAKE_DIR 		= $(shell pwd)
# in make path si trova il path del primo makefile usato (la cartella dove mi trovo)
MAKE_PATH 	   := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
CORE_V_VERIF   ?= $(MAKE_DIR)/core-v-verif
DATE 			= $(shell date +%F)
WAVES			= 0

# imposto il core nel caso in cui non viene fatto manualmente (mette anche i caratteri in minuscolo)
CV_CORE		   ?= CV32E40P
CV_CORE_LC     	= $(shell echo $(CV_CORE) | tr A-Z a-z)
CV_CORE_UC     	= $(shell echo $(CV_CORE) | tr a-z A-Z)
DESIGN_TB_DIR  ?= $(CORE_V_VERIF)/cv32e40p
SIMULATOR		= verilator
CV_SW_CFLAGS 	= -O2


# directories dei programmi di test
# utilizzo il path relativo perchè dice che verilator non regge path lunghi
## QUESTA PARTE VA MODIFICATA PERCHÈ DEVO METTERCI I MIEI FILE CHE DEVONO ESSERE ESEGUITI 
TEST_PROGRAM_PATH    ?= $(MAKE_DIR)/programs
TEST_PROGRAM_RELPATH ?= ./programs

# directories di output comuni
RUN_INDEX				?= 0
SIM_RESULTS				 = simulation_results
SIM_TEST_RESULTS		 = $(SIM_RESULTS)/$(TEST)
SIM_RUN_RESULTS			 = $(SIM_TEST_RESULTS)/$(RUN_INDEX)
SIM_TEST_PROGRAM_RESULTS = $(SIM_RUN_RESULTS)/test_program
SIM_BSP_RESULTS			 = $(SIM_TEST_PROGRAM_RESULTS)/bsp 

# eventuali flag
SV_CMP_FLAGS =

# programma da testare
TEST		?= swhw1

###############################################################################
# roba che non ho compreso (CHIEDI)
# Generate and include TEST_FLAGS_MAKE, based on the YAML test description.
YAML2MAKE = $(CORE_V_VERIF)/bin/yaml2make
TEST_FLAGS_MAKE := $(shell $(YAML2MAKE) --test=$(TEST) --yaml=test.yaml  $(YAML2MAKE_DEBUG) --run-index=$(u) --prefix=TEST --core=$(CV_CORE))
ifeq ($(TEST_FLAGS_MAKE),)
$(error ERROR Could not find test.yaml for test: $(TEST))
endif
include $(TEST_FLAGS_MAKE)

###############################################################################
# Makefiles comuni
#  -Variabili per l'RTL e altre dipendenze (e.g. RISCV_DV)
include $(CORE_V_VERIF)/cv32e40p/sim/ExternalRepos.mk
#  -core firmware e il toolchain GCC RISCV (SDK)
include $(CORE_V_VERIF)/mk/Common.mk

###############################################################################
# Configurazione variabili per verilator
VERILATOR 			?= /usr/local/bin/verilator
VERI_FLAGS			+=
SVERI_COMPILE_FLAGS += -Wno-BLKANDNBLK $(SV_CMP_FLAGS) # incoragiante commento (hope this doesn't hurt us in the long run)
VERI_TRACE			?= 
VERI_OBJ_DIR		?= cobj_dir
VERI_LOG_DIR		?= $(SIM_TEST_PROGRAM_RESULTS)
VERI_CFLAGS			+= -O2

###############################################################################
# Configurazione variabili per spike
GCC 		= $(CV_SW_PREFIX)gcc
AS 			= $(CV_SW_PREFIX)as
SRC_DIR 	= $(TEST_PROGRAM_PATH)/$(TEST)           # Cartella dove si trovano i file sorgenti
TARGET 		= $(TEST)_spike							# Nome dell'eseguibile

# Trova automaticamente i file .S e converte in file .o
ASM_SRCS 	= $(shell find $(SRC_DIR) -name '*.S')
ASM_OBJS 	= $(ASM_SRCS:.S=.o)

# Trova il file .c (deve essercene uno solo)
C_SRC 		= $(shell find $(SRC_DIR) -name '*.c')
C_OBJ 		= $(C_SRC:.c=.o)

# Tutti i file oggetto
OBJS 		= $(C_OBJ) $(ASM_OBJS)

# variabili di esecuzione
SPIKE 		= spike
SP_FLAGS   ?= pk

# variabili per risultato
OBJECTS		= objects
SPK_RESULTS	= spike_results
SPK_TEST_RESULTS		 = $(SPK_RESULTS)/$(TEST)
SPK_RUN_RESULTS			 = $(SPK_TEST_RESULTS)/$(OBJECTS)

###############################################################################
# source file del testbench per il core CV32E (anche se uso sempre lo stesso)
TBSRC_HOME	:= $(CORE_V_VERIF)/$(CV_CORE_LC)/tb
TBSRC_CORE	:= $(TBSRC_HOME)/core
TBSRC_TOP	:= $(TBSRC_CORE)/tb_top.sv 
TBSRC_PKG	:= $(TBSRC_CORE)/tb_riscv/include/perturbation_defines.sv
TBSRC 		:= $(TBSRC_CORE)/tb_top.sv \
			   $(TBSRC_CORE)/cv32e40p_tb_wrapper.sv \
               $(TBSRC_CORE)/mm_ram.sv \
               $(TBSRC_CORE)/dp_ram.sv \
			   $(TBSRC_CORE)/tb_riscv/riscv_random_stall.sv \
			   $(TBSRC_CORE)/tb_riscv/riscv_random_interrupt_generator.sv \
			   $(TBSRC_CORE)/tb_riscv/riscv_rvalid_stall.sv \
			   $(TBSRC_CORE)/tb_riscv/riscv_gnt_stall.sv

TBSRC_VERI  := $(TBSRC_CORE)/tb_top_verilator.sv \
				$(TBSRC_CORE)/cv32e40p_tb_wrapper.sv \
				$(TBSRC_CORE)/tb_riscv/riscv_rvalid_stall.sv \
				$(TBSRC_CORE)/tb_riscv/riscv_gnt_stall.sv \
				$(TBSRC_CORE)/mm_ram.sv \
				$(TBSRC_CORE)/dp_ram.sv

# RTL source files per il core 
# DESIGN_RTL_DIR è usato dal file CV_CORE_MANIFEST
CV_CORE_PKG				:= $(CORE_V_VERIF)/core-v-cores/$(CV_CORE_LC)
CV_CORE_RTLSRC_INCDIR	:= $(CV_CORE_PKG)/rtl/include
CV_CORE_RTLSRC_PKG		:= $(CV_CORE_PKG)/rtl/fpnew/src/fpnew_pkg.sv \
				$(addprefix $(CV_CORE_RTLSRC_INCDIR)/,\
				CV_CORE_apu_core_package.sv CV_CORE_defines.sv \
				CV_CORE_tracer_defines.sv)
CV_CORE_RTLSRC 	:= $(filter-out $(CV_CORE_PKG)/rtl/$(CV_CORE_LC)_register_file_latch.sv, \
				$(wildcard $(CV_CORE_PKG)/rtl/*.sv))
#### RIPORTO QUANTO SCRITTO NEL MAKEFILE ORIGINALE
# FIXME: temporarily using a local manifest for the core.
#        This is BAD PRACTICE and will be fixed with
#        https://github.com/openhwgroup/CV_CORE/pull/421 is resolved.

CV_CORE_MANIFEST		:= $(CV_CORE_PKG)/cv32e40p_manifest.flist
export DESIGN_RTL_DIR	 = $(CV_CORE_PKG)/rtl

# Shorthand rules for convience
CV_CORE_pkg: clone_$(CV_CORE_LC)_rtl

tbsrc_pkg: $(TBSRC_PKG)

tbsrc: $(TBSRC)

###############################################################################
#
#
# AGGIUNGERE GLI EVENTUALI PHONY riga 232
 .PHONY: hello-world
hello-world: $(SIMULATOR)-hello-world

.PHONY: cv32_riscv_tests
cv32_riscv_tests: $(SIMULATOR)-cv32_riscv_tests

.PHONY: cv32_riscv_tests-gui
cv32_riscv_tests-gui: $(SIMULATOR)-cv32_riscv_tests-gui

.PHONY: cv32_riscv_compliance_tests
cv32_riscv_compliance_tests: $(SIMULATOR)-cv32_riscv_compliance_tests

.PHONY: cv32_riscv_compliance_tests-gui
cv32_riscv_compliance_tests-gui: $(SIMULATOR)-cv32_riscv_compliance_tests-gui

.PHONY: firmware
firmware: $(SIMULATOR)-firmware

.PHONY: firmware-gui
firmware-gui: $(SIMULATOR)-firmware-gui

.PHONY: unit-test
unit-test: $(SIMULATOR)-unit-test

.PHONY: unit-test-gui
unit-test-gui: $(SIMULATOR)-unit-test-gui

# assume verilator se non ci altri target
GOAL		  ?= sanity-veri-run
.DEFAULT_GOAL := $(GOAL)


all: clean_all sanity-veri-run

#

###############################################################################
#
#
# AGGIUNGERE LA PARTE VERA E PROPRIA DI VERILATOR riga 470
#
# We first test if the user wants to to vcd dumping. This hacky part is required
# because we need to conditionally compile the testbench (-DVCD_TRACE) and pass
# the --trace flags to the verilator call
#ifeq ($(findstring +vcd,$(VERI_FLAGS)),+vcd)

ifneq (${WAVES}, 0)
VERI_TRACE="--trace"
VERI_CFLAGS+="-DVCD_TRACE"
endif

verilator: sanity-veri-run

verilate: testbench_verilator

sanity-veri-run:
	make veri-test $(TEST)

testbench_verilator: CV_CORE_pkg $(TBSRC_VERI) $(TBSRC_PKG)
	@echo "$(BANNER)"
	@echo "* Compiling CORE TB and CV32E40P with Verilator"
	@echo "$(BANNER)"
	$(VERILATOR) --cc --sv --exe \
		$(VERI_TRACE) \
		--Wno-lint --Wno-UNOPTFLAT \
		--Wno-MODDUP --top-module tb_top_verilator \
		--Wno-COMBDLY \
		--Wno-MULTIDRIVEN \
		--Wno-BLKANDNBLK \
		$(TBSRC_CORE)/tb_top_verilator.sv $(TBSRC_VERI) \
		-f $(CV_CORE_MANIFEST) \
		$(CV_CORE_PKG)/bhv/$(CV_CORE_LC)_core_log.sv \
		$(TBSRC_CORE)/tb_top_verilator.cpp --Mdir $(VERI_OBJ_DIR) \
		$(VERI_COMPILE_FLAGS)
	$(MAKE) -C $(VERI_OBJ_DIR) -f Vtb_top_verilator.mk
	mkdir -p $(SIM_RESULTS)
	mkdir -p $(SIM_TEST_RESULTS)
	mv $(VERI_OBJ_DIR)/Vtb_top_verilator $(SIM_TEST_RESULTS)/verilator_executable
	
veri-test: verilate $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
	@echo "$(BANNER)"
	@echo "* Running with Verilator: logfile in $(SIM_TEST_RESULTS)/$(TEST).log"
	@echo "$(BANNER)"
	mkdir -p $(VERI_LOG_DIR)
	$(SIM_TEST_RESULTS)/verilator_executable \
		$(VERI_FLAGS) \
		"+firmware=$(TEST_PROGRAM_RELPATH)/$(TEST)/$(TEST).hex" \
		| tee $(VERI_LOG_DIR)/$(TEST).log


# cleanup
veri-clean: verilate-clean

verilate-clean : tc-clean
	if [ -d $(SIM_RESULTS) ]; then rm -r $(SIM_RESULTS); fi
	if [ -d $(VERI_OBJ_DIR) ]; then rm -r $(VERI_OBJ_DIR); fi
	rm -rf testbench_verilator
	if [ -e memory_dump.bin ]; then rm memory_dump.bin; fi


###############################################################################
# CV_CORE RTL dipendenze

clone_$(CV_CORE_LC)_rtl:
	@echo "$(BANNER)"
	@echo "* Cloning CV32E40P RTL model"
	@echo "$(BANNER)"
	$(CLONE_CV_CORE_CMD)

###############################################################################
# target generali 
.PHONY: tc-clean

# clean up dei risultati di simulazione
clean-sim-results:
	rm -rf $(SIM_RESULTS)

#clean up dei file generati dal toolchain
clean-test-programs:
	find $(TEST_PROGRAM_PATH) -name *.on		-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name *.hex     	-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name *.elf     	-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name *.map     	-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name *.readelf 	-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name *.objdump 	-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name corev_*.S 	-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name *.itb	  	-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name *.dat	  	-exec rm {} \;
	find $(TEST_PROGRAM_PATH) -name *.vcd	  	-exec rm {} \;


.PHONY: clean
clean: verilate-clean clean-test-programs




###############################################################################
# simulazione con spike
# per chiamare spike si fa make GOAL=spike TEST=nometest*
spike: $(TARGET)
	mkdir -p $(SPK_RESULTS)
	mkdir -p $(SPK_TEST_RESULTS)
	mkdir -p $(SPK_RUN_RESULTS)
	$(foreach file, $(C_OBJ), mv $(file) $(SPK_RUN_RESULTS);)
	$(foreach file, $(ASM_OBJS), mv $(file) $(SPK_RUN_RESULTS);)
	$(SPIKE) $(SP_FLAGS) $(TARGET) 
	mv $(TARGET) $(SPK_TEST_RESULTS)
	


# Regola di default
$(TARGET): $(OBJS)
	$(GCC) $(OBJS) -o $(TARGET)


# Compilazione del file .c
$(C_OBJ): $(C_SRC)
	$(GCC) -c $(C_SRC) -o $(C_OBJ)

# Assemblo i file .S uno alla volta
$(ASM_OBJS):
	$(foreach file, $(ASM_SRCS), $(AS) $(file) -o $(file:.S=.o);)


# Pulizia
clean-spike:
	rm -rf $(SPK_RESULTS)

clean-spike-test:
	rm -rf $(SPK_TEST_RESULTS)



#endend