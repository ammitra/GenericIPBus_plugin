BUTOOL_PATH?=../../

CXX?=g++

IPBUS_REG_HELPER_PATH?=${BUTOOL_PATH}/plugins/BUTool-IPBUS-Helpers

LIBRARY_GENERIC_IPBUS_DEVICE = lib/libBUTool_GenericIPBusDevice.so
LIBRARY_GENERIC_IPBUS_DEVICE_SOURCES = $(wildcard src/GenericIPBus_device/*.cc)
LIBRARY_GENERIC_IPBUS_DEVICE_OBJECT_FILES = $(patsubst src/%.cc,obj/%.o,${LIBRARY_GENERIC_IPBUS_DEVICE_SOURCES})

LIBRARY_GENERIC_IPBUS = lib/libBUTool_GenericIPBus.so
LIBRARY_GENERIC_IPBUS_SOURCES = $(wildcard src/GenericIPBus/*.cc)
LIBRARY_GENERIC_IPBUS_OBJECT_FILES = $(patsubst src/%.cc,obj/%.o,${LIBRARY_GENERIC_IPBUS_SOURCES})

EXE_GENERIC_IPBUS_STANDALONE = bin/
EXE_GENERIC_IPBUS_STANDALONE_SOURCE = $(wildcard src/standalone/*.cxx)
EXE_GENERIC_IPBUS_STANDALONE_BIN = $(patsubst src/standalone/%.cxx,bin/%,${EXE_GENERIC_IPBUS_STANDALONE_SOURCE})
EXE_GENERIC_IPBUS_STANDALONE_SOURCES = $(wildcard src/standalone/*.cc)
EXE_GENERIC_IPBUS_STANDALONE_OBJECT_FILES += $(patsubst src/%.cc,obj/%.o,${EXE_GENERIC_IPBUS_STANDALONE_SOURCES})



INCLUDE_PATH = \
							-Iinclude  \
							-I$(BUTOOL_PATH)/include \
							-I$(IPBUS_REG_HELPER_PATH)/include

LIBRARY_PATH = \
							-Llib \
							-L$(BUTOOL_PATH)/lib \
							-L$(IPBUS_REG_HELPER_PATH)/lib

ifdef BOOST_INC
INCLUDE_PATH +=-I$(BOOST_INC)
endif
ifdef BOOST_LIB
LIBRARY_PATH +=-L$(BOOST_LIB)
endif

LIBRARIES =    	-lcurses \
		-lToolException	\
		-lBUTool_IPBusIO \
		-lBUTool_IPBusStatus \
		-lboost_regex \
		-lboost_filesystem




CXX_FLAGS = -std=c++11 -g -O3 -rdynamic -Wall -MMD -MP -fPIC ${INCLUDE_PATH} -Werror -Wno-literal-suffix

CXX_FLAGS +=-fno-omit-frame-pointer -Wno-ignored-qualifiers -Werror=return-type -Wextra -Wno-long-long -Winit-self -Wno-unused-local-typedefs  -Woverloaded-virtual ${COMPILETIME_ROOT} ${FALLTHROUGH_FLAGS}

LINK_LIBRARY_FLAGS = -shared -fPIC -Wall -g -O3 -rdynamic ${LIBRARY_PATH} ${LIBRARIES} -Wl,-rpath=$(RUNTIME_LDPATH)/lib ${COMPILETIME_ROOT}

LINK_EXE_FLAGS = -Wall -g -O3 -rdynamic ${LIBRARY_PATH} ${LIBRARIES} \
	         -L${COMPILETIME_ROOT}/lib/ -lBUTool_Helpers \
		 -Wl,-rpath=$(RUNTIME_LDPATH)/lib ${COMPILETIME_ROOT} 



# ------------------------
# IPBUS stuff
# ------------------------
UHAL_LIBRARIES = -lcactus_uhal_log 		\
                 -lcactus_uhal_grammars 	\
                 -lcactus_uhal_uhal 		

# Search uHAL library from $IPBUS_PATH first then from $CACTUS_ROOT
ifdef IPBUS_PATH
UHAL_INCLUDE_PATH = \
	         					-isystem$(IPBUS_PATH)/uhal/uhal/include \
	         					-isystem$(IPBUS_PATH)/uhal/log/include \
	         					-isystem$(IPBUS_PATH)/uhal/grammars/include 
UHAL_LIBRARY_PATH = \
								-L$(IPBUS_PATH)/uhal/uhal/lib \
	         					-L$(IPBUS_PATH)/uhal/log/lib \
	         					-L$(IPBUS_PATH)/uhal/grammars/lib \
							-L$(IPBUS_PATH)/extern/pugixml/pugixml-1.2/ 
else
UHAL_INCLUDE_PATH = \
	         					-isystem$(CACTUS_ROOT)/include 

UHAL_LIBRARY_PATH = \
							-L$(CACTUS_ROOT)/lib 
endif

UHAL_CXX_FLAGHS = ${UHAL_INCLUDE_PATH}

UHAL_LIBRARY_FLAGS = ${UHAL_LIBRARY_PATH}




.PHONY: all _all clean _cleanall build _buildall _cactus_env

default: build
clean: _cleanall
_cleanall:
	rm -rf obj
	rm -rf bin
	rm -rf lib


all: _all
build: _all
buildall: _all
_all: _cactus_env ${LIBRARY_GENERIC_IPBUS_DEVICE} ${LIBRARY_GENERIC_IPBUS} ${EXE_GENERIC_IPBUS_STANDALONE_BIN} #${EXE_GENERIC_IPBUS_STANDALONE}

_cactus_env:
ifdef IPBUS_PATH
	$(info using uHAL lib from user defined IPBUS_PATH=${IPBUS_PATH})
else ifdef CACTUS_ROOT
	$(info using uHAL lib from user defined CACTUS_ROOT=${CACTUS_ROOT})
else
	$(error Must define IPBUS_PATH or CACTUS_ROOT to include uHAL libraries (define through Makefile or command line\))
endif

# ------------------------
# GenericIPBus library
# ------------------------
${LIBRARY_GENERIC_IPBUS_DEVICE}: ${LIBRARY_GENERIC_IPBUS_DEVICE_OBJECT_FILES} ${IPBUS_REG_HELPER_PATH}/lib/libBUTool_IPBusIO.so ${LIBRARY_GENERIC_IPBUS}
	${CXX} ${LINK_LIBRARY_FLAGS} -lBUTool_GenericIPBus ${LIBRARY_GENERIC_IPBUS_DEVICE_OBJECT_FILES} -o $@
	@echo "export BUTOOL_AUTOLOAD_LIBRARY_LIST=\$$BUTOOL_AUTOLOAD_LIBRARY_LIST:$(RUNTIME_LDPATH)/${LIBRARY_GENERIC_IPBUS_DEVICE}" > env.sh

${LIBRARY_GENERIC_IPBUS}: ${LIBRARY_GENERIC_IPBUS_OBJECT_FILES} ${IPBUS_REG_HELPER_PATH}/lib/libBUTool_IPBusIO.so
	${CXX} ${LINK_LIBRARY_FLAGS}  ${LIBRARY_GENERIC_IPBUS_OBJECT_FILES} -o $@


obj/%.o : src/%.cc
	mkdir -p $(dir $@)
	mkdir -p {lib,obj}
	${CXX} ${CXX_FLAGS} ${UHAL_CXX_FLAGHS} -c $< -o $@

obj/%.o : src/%.cxx
	mkdir -p $(dir $@)
	mkdir -p {lib,obj}
	${CXX} ${CXX_FLAGS} ${UHAL_CXX_FLAGHS} -c $< -o $@

bin/% : obj/standalone/%.o
	mkdir -p bin
	${CXX} ${LINK_EXE_FLAGS} ${UHAL_LIBRARY_FLAGS} ${UHAL_LIBRARIES} -lBUTool_GenericIPBus -lboost_system -lpugixml ${EXE_GENERIC_IPBUS_STANDALONE_OBJECT_FILES} $^ -o $@


-include $(LIBRARY_OBJECT_FILES:.o=.d)

