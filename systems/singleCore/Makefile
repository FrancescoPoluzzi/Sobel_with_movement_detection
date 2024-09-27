SHELL=/bin/bash
PROJECT_TOP=config/project.toplevel
PROJECT_LIST=config/project.files
PROJECT_DEVICE_ALTERA=config/project.device.intel
PROJECT_OPTIONS=config/project.options
PROJECT_QSF=config/project.qsf
PROJECT_ALTERA=config/project.intel
PROJECT_SANDBOX=sandbox

REL_PATH=.
TOPLEVEL := $(shell cat $(REL_PATH)/$(PROJECT_TOP))
PROJECT_EDF=$(PROJECT_SANDBOX)/$(TOPLEVEL).edf
CP := $(shell which cp)

.PHONY: default clean $(PROJECT_SANDBOX) %

define make_intel_bit
if test ! -f $(PROJECT_TOP); then\
echo ""; echo ""; echo "ERROR: No file $(PROJECT_TOP) found!"; else\
if test ! -f $(PROJECT_LIST); then\
echo ""; echo ""; echo "ERROR: No file $(PROJECT_LIST) found!"; else\
if test ! -f $(PROJECT_QSF); then\
echo ""; echo ""; echo "ERROR: No file $(PROJECT_QSF) found!"; else\
if test ! -f $(PROJECT_DEVICE_ALTERA); then\
echo ""; echo ""; echo "ERROR: No file $(PROJECT_DEVICE_ALTERA) found!"; else\
if test ! -f $(PROJECT_ALTERA); then\
echo ""; echo ""; echo "ERROR: No file $(PROJECT_ALTERA) found!"; else\
echo "INFO: Performing automated altera bitfile generation...";\
mkdir -p $(PROJECT_SANDBOX);\
cd $(PROJECT_SANDBOX);\
echo "PROJECT_TOP=$(PROJECT_TOP)" > Makefile.intel;\
echo "PROJECT_LIST=$(PROJECT_LIST)" >> Makefile.intel;\
echo "PROJECT_OPTIONS=$(PROJECT_OPTIONS)" >> Makefile.intel;\
echo "PROJECT_QSF=$(PROJECT_QSF)" >> Makefile.intel;\
echo "PROJECT=$(PROJECT_ALTERA)" >> Makefile.intel;\
echo "PROJECT_DEVICE=$(PROJECT_DEVICE_ALTERA)" >> Makefile.intel;\
echo "REL_PATH=.." >> Makefile.intel;\
cat ../Makefile.intel >> Makefile.intel;\
$(MAKE) -f Makefile.intel;\
echo "****************************************************************************";\
echo 'INFO: copy the files $(PROJECT_SANDBOX)/$(TOPLEVEL).cfg and $(PROJECT_SANDBOX)/$(TOPLEVEL).rbf to your local machine. Execute "openocd -f $(TOPLEVEL).cfg" to download the bit-file to your board';\
echo "****************************************************************************";\
fi; fi; fi; fi; fi
endef #make intel bit

# echo "INFO: USE command < quartus_pgm -z --mode=JTAG -c 1 --operation=p;$(TOPLEVEL).sof > to download";\

define make_template
mkdir -p config
mkdir -p doc
mkdir -p $(PROJECT_SANDBOX)
mkdir -p verilog
endef

define make_sandbox
 if test ! -d $(PROJECT_SANDBOX) ; then\
  mkdir -p $(PROJECT_SANDBOX);\
 fi;
endef

default:
	@echo "==========================================================="
	@echo " Possible make targets are:"
	@echo ""
	@echo " clean: Remove all temporary files"
	@echo ""
	@echo " intel_bit: Generate a Altera bitfile for download. The"
	@echo "            files project.qsf, project.device.intel,"
	@echo "            project.toplevel, project.files, and project.intel"
	@echo "            in the directory config/ must exist for this "
	@echo "            command to work"
	@echo ""
	@echo "==========================================================="

clean: $(PROJECT_SANDBOX)
	@cd $(PROJECT_SANDBOX); find -type d | grep -v CVS | grep "/" | xargs rm -rf ; find -type f | grep -v CVS | xargs rm -f

sandbox:
	@$(make_sandbox)

intel_bit: $(PROJECT_SANDBOX)
	@$(make_intel_bit)

template:
	@$(make_template)

