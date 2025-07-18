# Copyright (c) 2010-2025, Lawrence Livermore National Security, LLC. Produced
# at the Lawrence Livermore National Laboratory. All Rights reserved. See files
# LICENSE and NOTICE for details. LLNL-CODE-806117.
#
# This file is part of the MFEM library. For more information and source code
# availability visit https://mfem.org.
#
# MFEM is free software; you can redistribute it and/or modify it under the
# terms of the BSD-3 license. We welcome feedback and contributions, see file
# CONTRIBUTING.md for details.

# The current MFEM version as an integer, see also `CMakeLists.txt`.
MFEM_VERSION = 40801
MFEM_VERSION_STRING = $(shell printf "%06d" $(MFEM_VERSION) | \
  sed -e 's/^0*\(.*.\)\(..\)\(..\)$$/\1.\2.\3/' -e 's/\.0/./g' -e 's/\.0$$//')

define MFEM_HELP_MSG

MFEM makefile targets:

   make config
   make
   make all
   make status/info
   make serial
   make parallel
   make debug
   make pdebug
   make cuda
   make hip
   make pcuda
   make cudebug
   make pcudebug
   make test/check
   make install
   make clean
   make distclean
   make style
   make tags
   make hooks

Examples:

make config MFEM_USE_MPI=YES MFEM_DEBUG=YES MPICXX=mpiCC
   Configure the make system for subsequent runs (analogous to a configure script).
   The available options are documented in the INSTALL file.
make config BUILD_DIR=<dir>
   Configure an out-of-source-tree build in the given directory.
make config -f <mfem-dir>/makefile
   Configure an out-of-source-tree build in the current directory.
make -j 4
   Build the library (in parallel) using the current configuration options.
make all
   Build the library, the examples and the miniapps using the current configuration.
make status
   Display information about the current configuration.
make serial
   A shortcut to configure and build the serial optimized version of the library.
make parallel
   A shortcut to configure and build the parallel optimized version of the library.
make debug
   A shortcut to configure and build the serial debug version of the library.
make pdebug
   A shortcut to configure and build the parallel debug version of the library.
make cuda
   A shortcut to configure and build the serial GPU/CUDA optimized version of the library.
make pcuda
   A shortcut to configure and build the parallel GPU/CUDA optimized version of the library.
make cudebug
   A shortcut to configure and build the serial GPU/CUDA debug version of the library.
make pcudebug
   A shortcut to configure and build the parallel GPU/CUDA debug version of the library.
make hip
   A shortcut to configure and build the serial GPU/HIP optimized version of the library.
make phip
   A shortcut to configure and build the parallel GPU/HIP optimized version of the library.
make hipdebug
   A shortcut to configure and build the serial GPU/HIP debug version of the library.
make phipdebug
   A shortcut to configure and build the parallel GPU/HIP debug version of the library.
make test
   Verify the build by checking the results from running all examples, miniapps,
   and tests.
make check
   Quick-check the build by compiling and running Example 1/1p.
make unittest
   Verify the build against the unit tests.
make install PREFIX=<dir>
   Install the library and headers in <dir>/lib and <dir>/include.
make clean
   Clean the library and object files, but keep the configuration.
make distclean
   In addition to "make clean", clean the configuration and remove the local
   installation directory.
make style
   Format the MFEM C++ source files using Artistic Style (astyle).
make tags
   Generate a vi or Emacs compatible TAGS file in ${MFEM_DIR}/TAGS. Requires
   functional "etags" and "egrep" in the user ${PATH}.
make hooks
   Creates symlinks to the hooks in the `.git/hooks` directory.
endef

# Save the MAKEOVERRIDES for cases where we explicitly want to pass the command
# line overrides to sub-make:
override MAKEOVERRIDES_SAVE := $(MAKEOVERRIDES)
# Do not pass down variables from the command-line to sub-make:
MAKEOVERRIDES =

# Path to the mfem source directory, defaults to this makefile's directory:
THIS_MK := $(lastword $(MAKEFILE_LIST))
$(if $(wildcard $(THIS_MK)),,$(error Makefile not found "$(THIS_MK)"))
MFEM_DIR ?= $(patsubst %/,%,$(dir $(THIS_MK)))
MFEM_REAL_DIR := $(realpath $(MFEM_DIR))
$(if $(MFEM_REAL_DIR),,$(error Source directory "$(MFEM_DIR)" is not valid))
SRC := $(if $(MFEM_REAL_DIR:$(CURDIR)=),$(MFEM_DIR)/,)
$(if $(word 2,$(SRC)),$(error Spaces in SRC = "$(SRC)" are not supported))

MFEM_GIT_STRING = $(shell [ -d $(MFEM_DIR)/.git ] && git -C $(MFEM_DIR) \
   describe --all --long --abbrev=40 --dirty --always 2> /dev/null)

# List of example subdirectories that require optional third-party packages.
# These directories are not distributed with this repository, so avoid
# descending into them by default.
EXAMPLE_SUBDIRS =
EXAMPLE_DIRS := examples $(addprefix examples/,$(EXAMPLE_SUBDIRS))
EXAMPLE_TEST_DIRS := examples

MINIAPP_SUBDIRS = common electromagnetics meshing navier performance tools \
 toys nurbs gslib adjoint solvers shifted mtop parelag tribol autodiff dfem \
 hooke multidomain dpg hdiv-linear-solver spde
MINIAPP_DIRS := $(addprefix miniapps/,$(MINIAPP_SUBDIRS))
MINIAPP_TEST_DIRS := $(filter-out %/common,$(MINIAPP_DIRS))
MINIAPP_USE_COMMON := $(addprefix miniapps/,electromagnetics meshing tools \
 toys shifted dpg)

EM_DIRS = $(EXAMPLE_DIRS) $(MINIAPP_DIRS)

TEST_SUBDIRS = unit
TEST_DIRS := $(addprefix tests/,$(TEST_SUBDIRS))

ALL_TEST_DIRS = $(filter-out\
   $(SKIP_TEST_DIRS),$(TEST_DIRS) $(EXAMPLE_TEST_DIRS) $(MINIAPP_TEST_DIRS))

# Use BUILD_DIR on the command line; set MFEM_BUILD_DIR before including this
# makefile or config/config.mk from a separate $(BUILD_DIR).
MFEM_BUILD_DIR ?= .
BUILD_DIR := $(MFEM_BUILD_DIR)
BUILD_REAL_DIR := $(abspath $(BUILD_DIR))
ifneq ($(BUILD_REAL_DIR),$(MFEM_REAL_DIR))
   BUILD_SUBDIRS = $(DIRS) config $(EM_DIRS) doc $(TEST_DIRS)
   CONFIG_FILE_DEF = -DMFEM_CONFIG_FILE='"$(BUILD_REAL_DIR)/config/_config.hpp"'
   BLD := $(if $(BUILD_REAL_DIR:$(CURDIR)=),$(BUILD_DIR)/,)
   $(if $(word 2,$(BLD)),$(error Spaces in BLD = "$(BLD)" are not supported))
else
   BUILD_DIR = $(MFEM_DIR)
   BLD := $(SRC)
endif
MFEM_BUILD_DIR := $(BUILD_DIR)

CONFIG_MK = $(BLD)config/config.mk

DEFAULTS_MK = $(SRC)config/defaults.mk
include $(DEFAULTS_MK)

# Optional user config file, see config/defaults.mk
USER_CONFIG = $(BLD)config/user.mk
-include $(USER_CONFIG)

# Helper print-info function
mfem-info = $(if $(filter YES,$(VERBOSE)),$(info *** [info]$(1)),)
export VERBOSE

$(call mfem-info, MAKECMDGOALS = $(MAKECMDGOALS))
$(call mfem-info, MAKEFLAGS    = $(MAKEFLAGS))
$(call mfem-info, MFEM_DIR  = $(MFEM_DIR))
$(call mfem-info, BUILD_DIR = $(BUILD_DIR))
$(call mfem-info, SRC       = $(SRC))
$(call mfem-info, BLD       = $(BLD))

# Include $(CONFIG_MK) unless some of the $(SKIP_INCLUDE_TARGETS) are given
SKIP_INCLUDE_TARGETS = help config clean distclean serial parallel debug pdebug\
 cuda hip pcuda phip cudebug hipdebug pcudebug phipdebug hpc style
HAVE_SKIP_INCLUDE_TARGET = $(filter $(SKIP_INCLUDE_TARGETS),$(MAKECMDGOALS))
ifeq (,$(HAVE_SKIP_INCLUDE_TARGET))
   $(call mfem-info, Including $(CONFIG_MK))
   -include $(CONFIG_MK)
else
   # Do not allow skip-include targets to be combined with other targets
   ifneq (1,$(words $(MAKECMDGOALS)))
      $(error Target '$(firstword $(HAVE_SKIP_INCLUDE_TARGET))' can not be\
      combined with other targets)
   endif
   $(call mfem-info, NOT including $(CONFIG_MK))
endif

# Compile flags used by MFEM: CPPFLAGS, CXXFLAGS, plus library flags
INCFLAGS =
# Link flags used by MFEM: library link flags plus LDFLAGS and LDFLAGS_INTERNAL
# (added at the end)
ALL_LIBS =

# Building static and/or shared libraries:
MFEM_STATIC ?= $(STATIC)
MFEM_SHARED ?= $(SHARED)
MFEM_SHARED_BUILD = $(MFEM_SHARED)

# Internal shortcuts
override static = $(if $(MFEM_STATIC:YES=),,YES)
override shared = $(if $(MFEM_SHARED:YES=),,YES)

# Error for package integrations that currently don't support single precision
ifeq ($(MFEM_USE_SINGLE),YES)
   PKGS_NO_SINGLE = SUNDIALS SUITESPARSE SUPERLU STRUMPACK GINKGO AMGX SLEPC\
	 PUMI GSLIB ALGOIM CEED MOONOLITH TRIBOL
   $(foreach pkg,$(PKGS_NO_SINGLE),$(if $(MFEM_USE_$(pkg):NO=),\
     $(error Package $(pkg) is NOT supported with single precision)))
endif

# The default value of CXXFLAGS is based on the value of MFEM_DEBUG
ifeq ($(MFEM_DEBUG),YES)
   CXXFLAGS ?= $(DEBUG_FLAGS)
endif
CXXFLAGS ?= $(OPTIM_FLAGS)

# MPI configuration
ifneq ($(MFEM_USE_MPI),YES)
   HOST_CXX = $(CXX)
   PKGS_NEED_MPI = SUPERLU MUMPS STRUMPACK PETSC PUMI SLEPC MKL_CPARDISO
   $(foreach mpidep,$(PKGS_NEED_MPI),$(if $(MFEM_USE_$(mpidep):NO=),\
     $(warning *** [MPI is OFF] setting MFEM_USE_$(mpidep) = NO)\
     $(eval override MFEM_USE_$(mpidep)=NO),))
else
   HOST_CXX = $(MPICXX)
   INCFLAGS += $(HYPRE_OPT)
   ALL_LIBS += $(HYPRE_LIB)
endif

# Default configuration
ifeq ($(MFEM_USE_CUDA)$(MFEM_USE_HIP),NONO)
   MFEM_CXX ?= $(HOST_CXX)
   MFEM_HOST_CXX ?= $(MFEM_CXX)
   XCOMPILER = $(CXX_XCOMPILER)
   XLINKER   = $(CXX_XLINKER)
endif

ifeq ($(MFEM_USE_CUDA),YES)
   MFEM_CXX ?= $(CUDA_CXX)
   ifeq ($(shell $(MFEM_CXX) --version 2>&1 | grep "NVIDIA"),)
      # assume clang
      MFEM_HOST_CXX ?= $(MFEM_CXX)
      CXXFLAGS += $(CLANG_CUDA_FLAGS)
      XCOMPILER = $(CXX_XCOMPILER)
      XLINKER   = $(CXX_XLINKER)
      CUDA_LIB := $(CLANG_CUDA_LIB) $(CUDA_LIB)
   else
      ifeq ($(MFEM_USE_ENZYME),YES)
         $(error Cannot use nvcc with Enzyme! Set CUDA_CXX to CUDA-enabled \
                 clang++ or an MPI wrapper of that)
      endif
      MFEM_HOST_CXX ?= $(HOST_CXX)
      CXXFLAGS += $(NVCC_FLAGS) -ccbin $(MFEM_HOST_CXX)
      XCOMPILER = $(CUDA_XCOMPILER)
      XLINKER   = $(CUDA_XLINKER)
   endif
   # CUDA_OPT and CUDA_LIB are added below
   # Compatibility test against MFEM_USE_HIP
   ifeq ($(MFEM_USE_HIP),YES)
      $(error Incompatible config: MFEM_USE_CUDA can not be combined with MFEM_USE_HIP)
   endif
endif

# HIP configuration
ifeq ($(MFEM_USE_HIP),YES)
   ifeq ($(MFEM_USE_MPI),YES)
      INCFLAGS += $(MPI_OPT)
      ALL_LIBS += $(MPI_LIB)
   endif
   MFEM_CXX ?= $(HIP_CXX)
   MFEM_HOST_CXX ?= $(MFEM_CXX)
   CXXFLAGS += $(HIP_FLAGS)
   XLINKER   = $(HIP_XLINKER)
   XCOMPILER = $(HIP_XCOMPILER)
   # HIP_OPT and HIP_LIB are added below
   # Compatibility test against MFEM_USE_CUDA
   ifeq ($(MFEM_USE_CUDA),YES)
      $(error Incompatible config: MFEM_USE_HIP can not be combined with MFEM_USE_CUDA)
   endif
endif

DEP_CXX ?= $(MFEM_CXX)

# Check legacy OpenMP configuration
ifeq ($(MFEM_USE_LEGACY_OPENMP),YES)
   MFEM_THREAD_SAFE ?= YES
   ifneq ($(MFEM_THREAD_SAFE),YES)
      $(error Incompatible config: MFEM_USE_LEGACY_OPENMP requires MFEM_THREAD_SAFE)
   endif
   # NOTE: MFEM_USE_LEGACY_OPENMP cannot be combined with any of:
   # MFEM_USE_OPENMP, MFEM_USE_CUDA, MFEM_USE_RAJA, MFEM_USE_OCCA
endif

# List of MFEM dependencies, that require the *_LIB variable to be non-empty
MFEM_REQ_LIB_DEPS = SUPERLU MUMPS METIS FMS CONDUIT SIDRE LAPACK SUNDIALS\
 SUITESPARSE STRUMPACK GINKGO GNUTLS HDF5 NETCDF SLEPC PETSC MPFR PUMI HIOP\
 GSLIB OCCA CEED RAJA UMPIRE MKL_CPARDISO MKL_PARDISO AMGX MAGMA CALIPER PARELAG\
 TRIBOL BENCHMARK MOONOLITH ALGOIM


PETSC_ERROR_MSG = $(if $(PETSC_FOUND),,. PETSC config not found: $(PETSC_VARS))
SLEPC_ERROR_MSG = $(if $(SLEPC_FOUND),,. SLEPC config not found: $(SLEPC_VARS))

define mfem_check_dependency
ifeq ($$(MFEM_USE_$(1)),YES)
   $$(if $$($(1)_LIB),,$$(error $(1)_LIB is empty$$($(1)_ERROR_MSG)))
endif
endef

# During configuration, check dependencies from MFEM_REQ_LIB_DEPS
ifeq ($(MAKECMDGOALS),config)
   $(foreach dep,$(MFEM_REQ_LIB_DEPS),\
      $(eval $(call mfem_check_dependency,$(dep))))
endif

# List of MFEM dependencies, processed below
MFEM_DEPENDENCIES = ENZYME $(MFEM_REQ_LIB_DEPS) LIBUNWIND OPENMP CUDA HIP

# List of deprecated MFEM dependencies, processed below
MFEM_LEGACY_DEPENDENCIES = OPENMP

# Macro for adding dependencies
define mfem_add_dependency
ifeq ($(MFEM_USE_$(1)),YES)
   INCFLAGS += $($(1)_OPT)
   ALL_LIBS += $($(1)_LIB)
endif
endef

# Macro for adding legacy dependencies
define mfem_add_legacy_dependency
ifeq ($(MFEM_USE_LEGACY_$(1)),YES)
   INCFLAGS += $($(1)_OPT)
   ALL_LIBS += $($(1)_LIB)
endif
endef

# Process dependencies
$(foreach dep,$(MFEM_DEPENDENCIES),$(eval $(call mfem_add_dependency,$(dep))))
$(foreach dep,$(MFEM_LEGACY_DEPENDENCIES),$(eval $(call \
   mfem_add_legacy_dependency,$(dep))))

# Timer option
ifeq ($(MFEM_TIMER_TYPE),2)
   ALL_LIBS += $(POSIX_CLOCKS_LIB)
endif

# zlib configuration
ifeq ($(MFEM_USE_ZLIB),YES)
   INCFLAGS += $(ZLIB_OPT)
   ALL_LIBS += $(ZLIB_LIB)
endif

# List of all defines that may be enabled in config.hpp and config.mk:
MFEM_DEFINES = MFEM_VERSION MFEM_VERSION_STRING MFEM_GIT_STRING MFEM_USE_MPI\
 MFEM_USE_METIS MFEM_USE_METIS_5 MFEM_DEBUG MFEM_USE_EXCEPTIONS MFEM_USE_ZLIB\
 MFEM_USE_LIBUNWIND MFEM_USE_LAPACK MFEM_THREAD_SAFE MFEM_USE_OPENMP\
 MFEM_USE_LEGACY_OPENMP MFEM_USE_MEMALLOC MFEM_TIMER_TYPE MFEM_USE_SUNDIALS\
 MFEM_USE_SUITESPARSE MFEM_USE_GINKGO MFEM_USE_SUPERLU MFEM_USE_SUPERLU5\
 MFEM_USE_STRUMPACK MFEM_USE_GNUTLS MFEM_USE_HDF5 MFEM_USE_NETCDF MFEM_USE_PETSC\
 MFEM_USE_SLEPC MFEM_USE_MPFR MFEM_USE_SIDRE MFEM_USE_FMS MFEM_USE_CONDUIT\
 MFEM_USE_PUMI MFEM_USE_HIOP MFEM_USE_GSLIB MFEM_USE_CUDA MFEM_USE_HIP\
 MFEM_USE_OCCA MFEM_USE_MOONOLITH MFEM_USE_CEED MFEM_USE_RAJA MFEM_USE_UMPIRE\
 MFEM_USE_SIMD MFEM_USE_ADIOS2 MFEM_USE_MKL_CPARDISO MFEM_USE_MKL_PARDISO MFEM_USE_AMGX\
 MFEM_USE_MAGMA MFEM_USE_MUMPS MFEM_USE_ADFORWARD MFEM_USE_CODIPACK MFEM_USE_CALIPER\
 MFEM_USE_BENCHMARK MFEM_USE_PARELAG MFEM_USE_TRIBOL MFEM_USE_ALGOIM MFEM_USE_ENZYME\
 MFEM_SOURCE_DIR MFEM_INSTALL_DIR MFEM_SHARED_BUILD MFEM_USE_DOUBLE MFEM_USE_SINGLE

# List of makefile variables that will be written to config.mk:
MFEM_CONFIG_VARS = MFEM_CXX MFEM_HOST_CXX MFEM_CPPFLAGS MFEM_CXXFLAGS\
 MFEM_INC_DIR MFEM_TPLFLAGS MFEM_INCFLAGS MFEM_PICFLAG MFEM_FLAGS MFEM_LIB_DIR\
 MFEM_EXT_LIBS MFEM_LIBS MFEM_LIB_FILE MFEM_STATIC MFEM_SHARED MFEM_BUILD_TAG\
 MFEM_PREFIX MFEM_CONFIG_EXTRA MFEM_MPIEXEC MFEM_MPIEXEC_NP MFEM_MPI_NP\
 MFEM_TEST_MK

# Config vars: values of the form @VAL@ are replaced by $(VAL) in config.mk
MFEM_CPPFLAGS  ?= $(CPPFLAGS)
MFEM_CXXFLAGS  ?= $(CXXFLAGS)
MFEM_TPLFLAGS  ?= $(INCFLAGS)
MFEM_INCFLAGS  ?= -I@MFEM_INC_DIR@ @MFEM_TPLFLAGS@
MFEM_PICFLAG   ?= $(if $(shared),$(PICFLAG))
MFEM_FLAGS     ?= @MFEM_CPPFLAGS@ @MFEM_CXXFLAGS@ @MFEM_INCFLAGS@
MFEM_EXT_LIBS  ?= $(ALL_LIBS) $(LDFLAGS) $(LDFLAGS_INTERNAL)
MFEM_LIBS      ?= $(if $(shared),$(BUILD_RPATH)) -L@MFEM_LIB_DIR@ -lmfem\
   @MFEM_EXT_LIBS@
MFEM_LIB_FILE  ?= @MFEM_LIB_DIR@/libmfem.$(if $(shared),$(SO_VER),a)
MFEM_BUILD_TAG ?= $(shell uname -snm)
MFEM_PREFIX    ?= $(PREFIX)
MFEM_INC_DIR   ?= $(if $(CONFIG_FILE_DEF),@MFEM_BUILD_DIR@,@MFEM_DIR@)
MFEM_LIB_DIR   ?= $(if $(CONFIG_FILE_DEF),@MFEM_BUILD_DIR@,@MFEM_DIR@)
MFEM_TEST_MK   ?= @MFEM_DIR@/config/test.mk
# Use "\n" (interpreted by sed) to add a newline.
MFEM_CONFIG_EXTRA ?= $(if $(CONFIG_FILE_DEF),MFEM_BUILD_DIR ?= @MFEM_DIR@,)

MFEM_SOURCE_DIR  = $(MFEM_REAL_DIR)
MFEM_INSTALL_DIR = $(abspath $(MFEM_PREFIX))

# If we have 'config' target, export variables used by config/makefile
ifneq (,$(filter config,$(MAKECMDGOALS)))
   export $(MFEM_DEFINES) MFEM_DEFINES $(MFEM_CONFIG_VARS) MFEM_CONFIG_VARS
   export VERBOSE HYPRE_OPT PUMI_DIR MUMPS_OPT GSLIB_OPT
endif

# If we have 'install' target, export variables used by config/makefile
ifneq (,$(filter install,$(MAKECMDGOALS)))
   ifneq (install,$(MAKECMDGOALS))
      $(error Target 'install' can not be combined with other targets)
   endif
   # Allow changing the PREFIX during install with: make install PREFIX=<dir>
   PREFIX := $(MFEM_PREFIX)
   PREFIX_INC   := $(PREFIX)/include
   PREFIX_LIB   := $(PREFIX)/lib
   PREFIX_SHARE := $(PREFIX)/share/mfem
   override MFEM_DIR := $(MFEM_REAL_DIR)
   MFEM_INCFLAGS = -I@MFEM_INC_DIR@ @MFEM_TPLFLAGS@
   MFEM_FLAGS    = @MFEM_CPPFLAGS@ @MFEM_CXXFLAGS@ @MFEM_INCFLAGS@
   MFEM_LIBS     = $(if $(shared),$(INSTALL_RPATH)) -L@MFEM_LIB_DIR@ -lmfem\
      @MFEM_EXT_LIBS@
   MFEM_LIB_FILE = @MFEM_LIB_DIR@/libmfem.$(if $(shared),$(SO_VER),a)
   ifeq ($(MFEM_USE_OCCA),YES)
      ifneq ($(MFEM_INSTALL_DIR),$(abspath $(PREFIX)))
         $(error OCCA is enabled: PREFIX must be set during configuration!)
      endif
   endif
   MFEM_PREFIX := $(abspath $(PREFIX))
   MFEM_INC_DIR = $(abspath $(PREFIX_INC))
   MFEM_LIB_DIR = $(abspath $(PREFIX_LIB))
   MFEM_TEST_MK = $(abspath $(PREFIX_SHARE)/test.mk)
   MFEM_CONFIG_EXTRA =
   export $(MFEM_DEFINES) MFEM_DEFINES $(MFEM_CONFIG_VARS) MFEM_CONFIG_VARS
   export VERBOSE
endif

# Source dirs in logical order
DIRS = general linalg linalg/batched linalg/simd mesh mesh/submesh fem \
       fem/ceed/integrators/mass fem/ceed/integrators/convection \
       fem/ceed/integrators/diffusion fem/ceed/integrators/nlconvection \
       fem/ceed/interface fem/ceed/solvers fem/eltrans fem/fe fem/gslib \
       fem/integ fem/lor fem/moonolith fem/qinterp fem/tmop fem/dfem

ifeq ($(MFEM_USE_MOONOLITH),YES)
   MFEM_CXXFLAGS += $(MOONOLITH_CXX_FLAGS)
   MFEM_INCFLAGS += -I$(MFEM_DIR)/fem/moonolith $(MOONOLITH_INCLUDES)
   MFEM_TPLFLAGS += $(MOONOLITH_INCLUDES)
   DIRS += fem/moonolith
endif

SOURCE_FILES = $(foreach dir,$(DIRS),$(wildcard $(SRC)$(dir)/*.cpp))
RELSRC_FILES = $(patsubst $(SRC)%,%,$(SOURCE_FILES))
OBJECT_FILES = $(patsubst $(SRC)%,$(BLD)%,$(SOURCE_FILES:.cpp=.o))
OKL_DIRS = fem

.PHONY: lib all clean distclean install config status info deps serial parallel	\
	debug pdebug cuda hip pcuda cudebug pcudebug hpc style check test unittest \
	deprecation-warnings

.SUFFIXES:
.SUFFIXES: .cpp .o
# Remove some default implicit rules
%:	%.o
%.o:	%.cpp
%:	%.cpp

# Default rule.
lib: $(if $(static),$(BLD)libmfem.a) $(if $(shared),$(BLD)libmfem.$(SO_EXT))

# Flags used for compiling all source files.
MFEM_BUILD_FLAGS = $(MFEM_PICFLAG) $(MFEM_CPPFLAGS) $(MFEM_CXXFLAGS)\
 $(MFEM_TPLFLAGS) $(CONFIG_FILE_DEF)

# Rules for compiling all source files.
$(OBJECT_FILES): $(BLD)%.o: $(SRC)%.cpp $(CONFIG_MK)
	$(MFEM_CXX) $(MFEM_BUILD_FLAGS) -c $(<) -o $(@)

all: examples miniapps $(TEST_DIRS)

.PHONY: miniapps $(EM_DIRS) $(TEST_DIRS)
miniapps: $(MINIAPP_DIRS)
$(MINIAPP_USE_COMMON): miniapps/common
$(EM_DIRS) $(TEST_DIRS): lib
	$(MAKE) -C $(BLD)$(@)

.PHONY: doc
doc:
	$(MAKE) -C $(BLD)$(@)

-include $(BLD)deps.mk

$(BLD)libmfem.a: $(OBJECT_FILES)
	$(AR) $(ARFLAGS) $(@) $(OBJECT_FILES)
	$(RANLIB) $(@)
	@$(MAKE) deprecation-warnings

$(BLD)libmfem.$(SO_EXT): $(BLD)libmfem.$(SO_VER)
	cd $(@D) && ln -sf $(<F) $(@F)
	@$(MAKE) deprecation-warnings

# If some of the external libraries are build without -fPIC, linking shared MFEM
# library may fail. In such cases, one may set EXT_LIBS on the command line.
EXT_LIBS = $(MFEM_EXT_LIBS)
$(BLD)libmfem.$(SO_VER): $(OBJECT_FILES)
	$(MFEM_CXX) $(MFEM_LINK_FLAGS) $(BUILD_SOFLAGS) $(OBJECT_FILES) \
	   $(EXT_LIBS) -o $(@)

# Shortcut targets options
serial debug cuda hip cudebug hipdebug:           M_MPI=NO
parallel pdebug pcuda pcudebug phip phipdebug:    M_MPI=YES
serial parallel cuda pcuda hip phip:              M_DBG=NO
debug pdebug cudebug pcudebug hipdebug phipdebug: M_DBG=YES
cuda pcuda cudebug pcudebug:                      M_CUDA=YES
hip phip hipdebug phipdebug:                      M_HIP=YES

serial parallel debug pdebug:
	$(MAKE) -f $(THIS_MK) config MFEM_USE_MPI=$(M_MPI) MFEM_DEBUG=$(M_DBG) \
	   $(MAKEOVERRIDES_SAVE)
	$(MAKE) $(MAKEOVERRIDES_SAVE)

cuda pcuda cudebug pcudebug:
	$(MAKE) -f $(THIS_MK) config MFEM_USE_MPI=$(M_MPI) MFEM_DEBUG=$(M_DBG) \
	   MFEM_USE_CUDA=$(M_CUDA) $(MAKEOVERRIDES_SAVE)
	$(MAKE) $(MAKEOVERRIDES_SAVE)

hip phip hipdebug phipdebug:
	$(MAKE) -f $(THIS_MK) config MFEM_USE_MPI=$(M_MPI) MFEM_DEBUG=$(M_DBG) \
	MFEM_USE_HIP=$(M_HIP) $(MAKEOVERRIDES_SAVE)
	$(MAKE) $(MAKEOVERRIDES_SAVE)

# Build with MPI and all Device backends enabled (requires OCCA and RAJA)
hpc:
	$(MAKE) -f $(THIS_MK) config MFEM_USE_MPI=YES MFEM_USE_CUDA=YES \
	  MFEM_USE_OPENMP=YES MFEM_USE_OCCA=YES MFEM_USE_RAJA=YES \
	  $(MAKEOVERRIDES_SAVE)
	$(MAKE) $(MAKEOVERRIDES_SAVE)

deps:
	rm -f $(BLD)deps.mk
	for i in $(RELSRC_FILES:.cpp=); do \
	   $(DEP_CXX) $(MFEM_BUILD_FLAGS) $(DEP_FLAGS) $(BLD)$${i}.o $(SRC)$${i}.cpp\
	      >> $(BLD)deps.mk; done

check: lib
	@printf "Quick-checking the MFEM library."
	@printf " Use 'make test' for more extensive tests.\n"
	@$(MAKE) -C $(BLD)examples \
	$(if $(findstring YES,$(MFEM_USE_MPI)),ex1p-test-par,ex1-test-seq)

test test-noclean:
	@echo "Testing the MFEM library. This may take a while..."
	@echo "Building all examples, miniapps, and tests..."
	@$(MAKE) $(MAKEOVERRIDES_SAVE) all
	@echo "Running tests in: [ $(ALL_TEST_DIRS) ] ..."
	@ERR=0; for dir in $(ALL_TEST_DIRS); do \
	   echo "Running tests in $${dir} ..."; \
	   if ! $(MAKE) -j1 -C $(BLD)$${dir} $@; then \
	   ERR=1; fi; done; \
	   if [ 0 -ne $${ERR} ]; then echo "Some tests failed."; exit 1; \
	   else echo "All tests passed."; fi

.PHONY: test-miniapps
test-miniapps:
	@echo "Building all miniapps ..."
	@$(MAKE) $(MAKEOVERRIDES_SAVE) miniapps
	@ERR=0; for dir in $(MINIAPP_TEST_DIRS); do \
	   echo "Running tests in $${dir} ..."; \
	   if ! $(MAKE) -j1 -C $(BLD)$${dir} test; then \
	   ERR=1; fi; done; \
	   if [ 0 -ne $${ERR} ]; then echo "Some miniapp tests failed."; \
	   exit 1; else echo "All miniapp tests passed."; fi

unittest: lib
	$(MAKE) -C $(BLD)tests/unit test

.PHONY: test-print
test-print:
	@echo "Printing tests in: [ $(ALL_TEST_DIRS) ] ..."
	@for dir in $(ALL_TEST_DIRS); do \
	   $(MAKE) -j1 -C $(BLD)$${dir} test-print; done

ALL_CLEAN_SUBDIRS = $(addsuffix /clean,config $(EM_DIRS) doc $(TEST_DIRS))
.PHONY: $(ALL_CLEAN_SUBDIRS) miniapps/clean
miniapps/clean: $(addsuffix /clean,$(MINIAPP_DIRS))
$(ALL_CLEAN_SUBDIRS):
	$(MAKE) -C $(BLD)$(@D) $(@F)

clean: $(addsuffix /clean,$(EM_DIRS) $(TEST_DIRS))
	rm -f $(addprefix $(BLD),$(foreach d,$(DIRS),$(d)/*.o))
	rm -f $(addprefix $(BLD),$(foreach d,$(DIRS),$(d)/*~))
	rm -rf $(addprefix $(BLD),*~ libmfem.* deps.mk)

distclean: clean config/clean doc/clean
	rm -rf mfem/

# User-definable install permissions.
# Install permissions for everything except directories and binaries:
INSTALL_DEF_PERM ?= 644
# Install permissions for binaries:
INSTALL_BIN_PERM ?= 755
# Install permissions for directories (and symlinks on macOS/BSD):
INSTALL_DIR_PERM ?= 755

# Shortcuts, not to be modified by the user on the command line.
# We use 'umask' because 'mkdir -p' (and 'install -d') do not use the mode
# specified with the '-m' flag when creating non-existent parent directories.
# WARNING: $(MKINSTALLDIR) changes the umask for commands following it as part
#          of the same shell expression unless it is placed inside '()' to be
#          executed in a sub-shell.
override INSTALLDEF   = $(INSTALL) -m $(INSTALL_DEF_PERM)
override INSTALLMASK  = $(shell printf "%o" $$((~0$(INSTALL_DIR_PERM) & 0777)))
override MKINSTALLDIR = umask $(INSTALLMASK) && mkdir -p

INSTALL_SHARED_LIB = $(MFEM_CXX) $(MFEM_LINK_FLAGS) $(INSTALL_SOFLAGS)\
   $(OBJECT_FILES) $(EXT_LIBS) -o $(PREFIX_LIB)/libmfem.$(SO_VER) && \
   cd $(PREFIX_LIB) && chmod $(INSTALL_BIN_PERM) libmfem.$(SO_VER) && \
   ( umask $(INSTALLMASK) && ln -sf libmfem.$(SO_VER) libmfem.$(SO_EXT) )

install: $(if $(static),$(BLD)libmfem.a) $(if $(shared),$(BLD)libmfem.$(SO_EXT))
	$(MKINSTALLDIR) $(PREFIX_LIB)
# install static and/or shared library
	$(if $(static),$(INSTALLDEF) $(BLD)libmfem.a $(PREFIX_LIB))
	$(if $(shared),$(INSTALL_SHARED_LIB))
# install top level includes
	$(MKINSTALLDIR) $(PREFIX_INC)/mfem
	$(INSTALLDEF) $(SRC)mfem.hpp $(SRC)mfem-performance.hpp \
	   $(PREFIX_INC)/mfem
	for hdr in mfem.hpp mfem-performance.hpp; do \
	   printf '// Auto-generated file.\n#include "mfem/'$$hdr'"\n' \
	      > $(PREFIX_INC)/$$hdr && \
	   chmod $(INSTALL_DEF_PERM) $(PREFIX_INC)/$$hdr; done
# install config include
	$(MKINSTALLDIR) $(PREFIX_INC)/mfem/config
	$(INSTALLDEF) $(BLD)config/_config.hpp $(PREFIX_INC)/mfem/config
	$(INSTALLDEF) $(SRC)config/config.hpp $(PREFIX_INC)/mfem/config
	$(INSTALLDEF) $(SRC)config/tconfig.hpp $(PREFIX_INC)/mfem/config
# install remaining includes in each subdirectory
	for dir in $(DIRS); do \
	   if ls $(SRC)$$dir/*.hpp > /dev/null 2>&1; then \
	      ( $(MKINSTALLDIR) $(PREFIX_INC)/mfem/$$dir ) && \
	      $(INSTALLDEF) $(SRC)$$dir/*.hpp $(PREFIX_INC)/mfem/$$dir; \
	   fi; \
	done
# install *.okl files
	for dir in $(OKL_DIRS); do \
	   ( $(MKINSTALLDIR) $(PREFIX_INC)/mfem/$$dir ) && \
	   $(INSTALLDEF) $(SRC)$$dir/*.okl $(PREFIX_INC)/mfem/$$dir; \
	done
# install libCEED q-function headers
	$(MKINSTALLDIR) $(PREFIX_INC)/mfem/fem/ceed/integrators/mass
	$(INSTALLDEF) $(SRC)fem/ceed/integrators/mass/*.h \
	   $(PREFIX_INC)/mfem/fem/ceed/integrators/mass
	$(MKINSTALLDIR) $(PREFIX_INC)/mfem/fem/ceed/integrators/convection
	$(INSTALLDEF) $(SRC)fem/ceed/integrators/convection/*.h \
	   $(PREFIX_INC)/mfem/fem/ceed/integrators/convection
	$(MKINSTALLDIR) $(PREFIX_INC)/mfem/fem/ceed/integrators/diffusion
	$(INSTALLDEF) $(SRC)fem/ceed/integrators/diffusion/*.h \
	   $(PREFIX_INC)/mfem/fem/ceed/integrators/diffusion
	$(MKINSTALLDIR) $(PREFIX_INC)/mfem/fem/ceed/integrators/nlconvection
	$(INSTALLDEF) $(SRC)fem/ceed/integrators/nlconvection/*.h \
	   $(PREFIX_INC)/mfem/fem/ceed/integrators/nlconvection
# install config.mk in $(PREFIX_SHARE)
	$(MKINSTALLDIR) $(PREFIX_SHARE)
	$(MAKE) -C $(BLD)config config-mk CONFIG_MK=config-install.mk
	$(INSTALLDEF) $(BLD)config/config-install.mk $(PREFIX_SHARE)/config.mk
	rm -f $(BLD)config/config-install.mk
# install test.mk in $(PREFIX_SHARE)
	$(INSTALLDEF) $(SRC)config/test.mk $(PREFIX_SHARE)

$(CONFIG_MK):
# Skip the error message when '-B' make flag is used (unconditionally
# make all targets), but still check for the $(CONFIG_MK) file
ifeq (,$(and $(findstring B,$(MAKEFLAGS)),$(wildcard $(CONFIG_MK))))
	$(info )
	$(info MFEM is not configured.)
	$(info Run "make config" first, or see "make help".)
	$(info )
	$(error )
endif

config: $(if $(CONFIG_FILE_DEF),build-config,local-config)

.PHONY: local-config
local-config:
	$(MAKE) -C config all
	@printf "\nBuild destination: <source> [$(BUILD_REAL_DIR)]\n\n"

.PHONY: build-config
build-config:
	for d in $(BUILD_SUBDIRS); do mkdir -p $(BLD)$${d}; done
	for dir in "" $(addsuffix /,config $(EM_DIRS) doc $(TEST_DIRS)); do \
	   printf "# Auto-generated file.\n%s\n%s\n" \
	      "MFEM_DIR = $(MFEM_REAL_DIR)" \
	      "include \$$(MFEM_DIR)/$${dir}makefile" \
	      > $(BLD)$${dir}GNUmakefile; done
	$(MAKE) -C $(BLD)config all
	cd "$(BUILD_DIR)" && ln -sf "$(MFEM_REAL_DIR)/data" .
	for hdr in mfem.hpp mfem-performance.hpp; do \
	   printf "// Auto-generated file.\n%s\n%s\n" \
	   "#define MFEM_CONFIG_FILE \"$(BUILD_REAL_DIR)/config/_config.hpp\"" \
	   "#include \"$(MFEM_REAL_DIR)/$${hdr}\"" > $(BLD)$${hdr}; done
	@printf "\nBuild destination: $(BUILD_DIR) [$(BUILD_REAL_DIR)]\n\n"

help:
	$(info $(value MFEM_HELP_MSG))
	@true

status info:
	$(info MFEM_VERSION           = $(MFEM_VERSION) [v$(MFEM_VERSION_STRING)])
	$(info MFEM_GIT_STRING        = $(MFEM_GIT_STRING))
	$(info MFEM_USE_MPI           = $(MFEM_USE_MPI))
	$(info MFEM_USE_METIS         = $(MFEM_USE_METIS))
	$(info MFEM_USE_METIS_5       = $(MFEM_USE_METIS_5))
	$(info MFEM_PRECISION         = \
	   $(if $(MFEM_USE_SINGLE:NO=),single,double))
	$(info MFEM_USE_DOUBLE        = $(MFEM_USE_DOUBLE))
	$(info MFEM_USE_SINGLE        = $(MFEM_USE_SINGLE))
	$(info MFEM_DEBUG             = $(MFEM_DEBUG))
	$(info MFEM_USE_EXCEPTIONS    = $(MFEM_USE_EXCEPTIONS))
	$(info MFEM_USE_ZLIB          = $(MFEM_USE_ZLIB))
	$(info MFEM_USE_LIBUNWIND     = $(MFEM_USE_LIBUNWIND))
	$(info MFEM_USE_LAPACK        = $(MFEM_USE_LAPACK))
	$(info MFEM_THREAD_SAFE       = $(MFEM_THREAD_SAFE))
	$(info MFEM_USE_OPENMP        = $(MFEM_USE_OPENMP))
	$(info MFEM_USE_LEGACY_OPENMP = $(MFEM_USE_LEGACY_OPENMP))
	$(info MFEM_USE_MEMALLOC      = $(MFEM_USE_MEMALLOC))
	$(info MFEM_TIMER_TYPE        = $(MFEM_TIMER_TYPE))
	$(info MFEM_USE_SUNDIALS      = $(MFEM_USE_SUNDIALS))
	$(info MFEM_USE_SUITESPARSE   = $(MFEM_USE_SUITESPARSE))
	$(info MFEM_USE_SUPERLU       = $(MFEM_USE_SUPERLU))
	$(info MFEM_USE_SUPERLU5      = $(MFEM_USE_SUPERLU5))
	$(info MFEM_USE_MUMPS         = $(MFEM_USE_MUMPS))
	$(info MFEM_USE_STRUMPACK     = $(MFEM_USE_STRUMPACK))
	$(info MFEM_USE_GINKGO        = $(MFEM_USE_GINKGO))
	$(info MFEM_USE_AMGX          = $(MFEM_USE_AMGX))
	$(info MFEM_USE_MAGMA         = $(MFEM_USE_MAGMA))
	$(info MFEM_USE_GNUTLS        = $(MFEM_USE_GNUTLS))
	$(info MFEM_USE_HDF5          = $(MFEM_USE_HDF5))
	$(info MFEM_USE_NETCDF        = $(MFEM_USE_NETCDF))
	$(info MFEM_USE_PETSC         = $(MFEM_USE_PETSC))
	$(info MFEM_USE_SLEPC         = $(MFEM_USE_SLEPC))
	$(info MFEM_USE_MPFR          = $(MFEM_USE_MPFR))
	$(info MFEM_USE_SIDRE         = $(MFEM_USE_SIDRE))
	$(info MFEM_USE_FMS           = $(MFEM_USE_FMS))
	$(info MFEM_USE_CONDUIT       = $(MFEM_USE_CONDUIT))
	$(info MFEM_USE_PUMI          = $(MFEM_USE_PUMI))
	$(info MFEM_USE_HIOP          = $(MFEM_USE_HIOP))
	$(info MFEM_USE_GSLIB         = $(MFEM_USE_GSLIB))
	$(info MFEM_USE_CUDA          = $(MFEM_USE_CUDA))
	$(info MFEM_USE_HIP           = $(MFEM_USE_HIP))
	$(info MFEM_USE_RAJA          = $(MFEM_USE_RAJA))
	$(info MFEM_USE_OCCA          = $(MFEM_USE_OCCA))
	$(info MFEM_USE_CALIPER       = $(MFEM_USE_CALIPER))
	$(info MFEM_USE_ALGOIM        = $(MFEM_USE_ALGOIM))
	$(info MFEM_USE_CEED          = $(MFEM_USE_CEED))
	$(info MFEM_USE_UMPIRE        = $(MFEM_USE_UMPIRE))
	$(info MFEM_USE_SIMD          = $(MFEM_USE_SIMD))
	$(info MFEM_USE_ADIOS2        = $(MFEM_USE_ADIOS2))
	$(info MFEM_USE_MKL_CPARDISO  = $(MFEM_USE_MKL_CPARDISO))
	$(info MFEM_USE_MKL_PARDISO   = $(MFEM_USE_MKL_PARDISO))
	$(info MFEM_USE_MOONOLITH     = $(MFEM_USE_MOONOLITH))
	$(info MFEM_USE_ADFORWARD     = $(MFEM_USE_ADFORWARD))
	$(info MFEM_USE_CODIPACK      = $(MFEM_USE_CODIPACK))
	$(info MFEM_USE_BENCHMARK     = $(MFEM_USE_BENCHMARK))
	$(info MFEM_USE_PARELAG       = $(MFEM_USE_PARELAG))
	$(info MFEM_USE_TRIBOL        = $(MFEM_USE_TRIBOL))
	$(info MFEM_USE_ENZYME        = $(MFEM_USE_ENZYME))
	$(info MFEM_CXX               = $(value MFEM_CXX))
	$(info MFEM_HOST_CXX          = $(value MFEM_HOST_CXX))
	$(info MFEM_CPPFLAGS          = $(value MFEM_CPPFLAGS))
	$(info MFEM_CXXFLAGS          = $(value MFEM_CXXFLAGS))
	$(info MFEM_TPLFLAGS          = $(value MFEM_TPLFLAGS))
	$(info MFEM_INCFLAGS          = $(value MFEM_INCFLAGS))
	$(info MFEM_FLAGS             = $(value MFEM_FLAGS))
	$(info MFEM_LINK_FLAGS        = $(value MFEM_LINK_FLAGS))
	$(info MFEM_EXT_LIBS          = $(value MFEM_EXT_LIBS))
	$(info MFEM_LIBS              = $(value MFEM_LIBS))
	$(info MFEM_LIB_FILE          = $(value MFEM_LIB_FILE))
	$(info MFEM_BUILD_TAG         = $(value MFEM_BUILD_TAG))
	$(info MFEM_PREFIX            = $(value MFEM_PREFIX))
	$(info MFEM_INC_DIR           = $(value MFEM_INC_DIR))
	$(info MFEM_LIB_DIR           = $(value MFEM_LIB_DIR))
	$(info MFEM_STATIC            = $(MFEM_STATIC))
	$(info MFEM_SHARED            = $(MFEM_SHARED))
	$(info MFEM_BUILD_DIR         = $(MFEM_BUILD_DIR))
	$(info MFEM_MPIEXEC           = $(MFEM_MPIEXEC))
	$(info MFEM_MPIEXEC_NP        = $(MFEM_MPIEXEC_NP))
	$(info MFEM_MPI_NP            = $(MFEM_MPI_NP))
	@true

ASTYLE_BIN = astyle
ASTYLE = $(ASTYLE_BIN) --options=$(SRC)config/mfem.astylerc
ASTYLE_VER = "Artistic Style Version 3.1"
FORMAT_FILES = $(foreach dir,$(DIRS) $(EM_DIRS) config,$(dir)/*.?pp)
TESTS_SUBDIRS = unit benchmarks convergence mem_manager par-mesh-format
UNIT_TESTS_SUBDIRS = general linalg mesh fem miniapps ceed enzyme
MINIAPPS_SUBDIRS = dpg/util hooke/operators hooke/preconditioners hooke/materials hooke/kernels
FORMAT_FILES += $(foreach dir,$(TESTS_SUBDIRS),tests/$(dir)/*.?pp)
FORMAT_FILES += $(foreach dir,$(UNIT_TESTS_SUBDIRS),tests/unit/$(dir)/*.?pp)
FORMAT_FILES += $(foreach dir,$(MINIAPPS_SUBDIRS),miniapps/$(dir)/*.?pp)
FORMAT_EXCLUDE = general/tinyxml2.cpp tests/unit/catch.hpp
FORMAT_LIST = $(filter-out $(FORMAT_EXCLUDE),$(wildcard $(FORMAT_FILES)))

COUT_CERR_FILES = $(foreach dir,$(DIRS),$(dir)/*.[ch]pp)
COUT_CERR_EXCLUDE = '^general/error\.cpp' '^general/globals\.[ch]pp'

DEPRECATION_WARNING := \
"This feature is planned for removal in the next release."\
"Please open an issue at github.com/mfem/mfem/issues if you depend on it."
deprecation-warnings:
	@if [ -t 1 ]; then\
	   red="\033[0;31m"; yellow="\033[0;33m"; end="\033[0m";\
	 fi;\
	if [ $(MFEM_USE_LEGACY_OPENMP) = YES ]; then\
	  printf $$red"[MFEM_USE_LEGACY_OPENMP]"$$end": "$$yellow"%s"$$end"\n"\
	  $(DEPRECATION_WARNING);\
	fi

# $(call mfem_check_command, command-to-execute, success_msg, failed_msg)
mfem_check_command = \
  if [ -t 1 ]; then red="\033[0;31m"; green="\033[0;32m"; end="\033[0m"; fi;\
  if ! $(1); then\
    printf $$green"%s"$$end"\n" "[  OK  ] "$(strip $(2));\
  else\
    printf $$red"%s"$$end"\n"   "[FAILED] "$(strip $(3)); err_code=1;\
  fi

# Verify the C++ code styling in MFEM and check that std::cout and std::cerr are
# not used in the library (use mfem::out and mfem::err instead).
style:
	@echo "Applying C++ code style..."
	@astyle_version="$$($(ASTYLE_BIN) --version)";\
	 if [ "$$astyle_version" != $(ASTYLE_VER) ]; then\
	    printf "%s\n" "Invalid astyle version: '$$astyle_version'"\
	           "Please use: '"$(ASTYLE_VER)"'";\
	    exit 1;\
	 fi
	@err_code=0;\
	$(call mfem_check_command,\
	    $(ASTYLE) $(FORMAT_LIST) | grep Formatted,\
	    "No source files were changed",\
	    "Please make sure the changes are committed");\
	echo "Checking for use of std::cout...";\
	$(call mfem_check_command,\
	   grep cout $(COUT_CERR_FILES) | grep -v $(COUT_CERR_EXCLUDE:%=-e %),\
	   "No use of std::cout found", "Use mfem::out instead of std::cout");\
	echo "Checking for use of std::cerr...";\
	$(call mfem_check_command,\
	   grep cerr $(COUT_CERR_FILES) |\
	      grep -v $(COUT_CERR_EXCLUDE:%=-e %) -e cerrno,\
	   "No use of std::cerr found", "Use mfem::err instead of std::cerr");\
	exit $$err_code

# Generate a TAGS table in $MFEM_DIR from all the tracked files
.PHONY: tags
tags:
ifndef ETAGS_BIN
	$(error Error could not find suitable 'etags', please install one \
	using your package manager)
else ifndef EGREP_BIN
	$(error Error could not find suitable 'egrep', please install one \
	using your package manager)
endif
	$(eval MFEM_TRACKED_SOURCE = $(shell git -C $(MFEM_REAL_DIR) ls-files |\
	$(EGREP_BIN) '(\.[hc](pp)?)$$'))
	@cd $(MFEM_REAL_DIR) && $(ETAGS_BIN) --class-qualify \
	--declarations -o $(MFEM_REAL_DIR)/TAGS $(MFEM_TRACKED_SOURCE)

# Creates symlinks to the hooks in the `.git/hooks` directory. Individual
# hooks can be enabled by manually creating symlinks. Hooks can be customized
# using hard copies (trading off with automated updates).
.PHONY: hooks
hooks:
	@cd $(MFEM_DIR)/.git/hooks && \
	ln -s ../../config/githooks/pre-commit pre-commit; \
	ln -s ../../config/githooks/pre-push pre-push;

# Print the contents of a makefile variable, e.g.: 'make print-MFEM_LIBS'.
print-%:
	$(info [ variable name]: $*)
	$(info [        origin]: $(origin $*))
	$(info [         value]: $(value $*))
	$(info [expanded value]: $($*))
	$(info )
	@true

# Print the contents of all makefile variables.
.PHONY: printall
printall: $(subst :,\:,$(foreach var,$(.VARIABLES),print-$(var)))
	@true
