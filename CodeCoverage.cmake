# Copyright (c) 2015, Philipp Harms
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if(NOT DEFINED CodeCov_BUILD_COVERAGE)
  option(CodeCov_BUILD_COVERAGE "Build coverage targets" On)
endif()

function(_codecov_failure_message msg)
  message(FATAL_ERROR "${msg}")
endfunction()

function(_codecov_gnu_setup)
  find_program(CodeCov_GNU_LCOV lcov)
  find_program(CodeCov_GNU_GENHTML genhtml)

  set(_missing_programs)
  if(NOT CodeCov_GNU_LCOV)
    list(APPEND _missing_programs "lcov")
  endif()

  if(NOT CodeCov_GNU_GENHTML)
    list(APPEND _missing_programs "genhtml")
  endif()

  if(_missing_programs)
    string(REPLACE ";" ", " _missing_programs ${_missing_programs})
    string(CONCAT _message "Could not find ${_missing_programs}")

    _codecov_failure_message(${_message})
  endif()

  mark_as_advanced(CodeCov_GNU_LCOV CodeCov_GNU_GENHTML)

  add_custom_target(codecov_prerun
    ${CodeCov_GNU_LCOV} --quiet --rc lcov_branch_coverage=1 --directory . --zerocounters
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  COMMENT "Cleaning up coverage statistics")

  add_custom_target(codecov_postrun
    ${CodeCov_GNU_LCOV} --quiet --rc lcov_branch_coverage=1 --directory . --capture --output-file coverage.info
    COMMAND ${CodeCov_GNU_LCOV} --quiet --rc lcov_branch_coverage=1 --remove coverage.info '/usr/*' --output-file coverage.info.cleaned
    COMMAND ${CodeCov_GNU_LCOV} --rc lcov_branch_coverage=1 --summary coverage.info.cleaned
    COMMAND ${CodeCov_GNU_GENHTML} --quiet --rc lcov_branch_coverage=1 -o coverage coverage.info.cleaned
    COMMAND ${CMAKE_COMMAND} -E remove ${_outputname}.info ${_outputname}.info.cleaned

    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Generating coverage report")

  add_custom_target(coverage DEPENDS codecov_postrun)
endfunction()

function(enable_coverage lang)
  if(CodeCov_${lang}_IS_INITIALIZED)
    return()
  endif()

  if(NOT CMAKE_${lang}_COMPILER_LOADED)
    enable_language(${lang})
  endif()

  if(CMAKE_${lang}_COMPILER_ID STREQUAL "GNU")
    if(CMAKE_${lang}_COMPILER_VERSION VERSION_LESS "4.1.0")
      set(CodeCov_${lang}_FLAGS_INTERNAL "-g" "-O0" "-fprofile-arcs" "-ftest-coverage")
      set(CodeCov_${lang}_LINK_FLAGS_INTERNAL "-fprofile-arcs -ftest-coverage")
    else()
      set(CodeCov_${lang}_FLAGS_INTERNAL "-g" "-O0" "--coverage")
      set(CodeCov_${lang}_LINK_FLAGS_INTERNAL "--coverage")
    endif()
  elseif(CMAKE_${lang}_COMPILER_ID STREQUAL "Clang")
    include(Check${lang}CompilerFlag)
    if(${lang} STREQUAL "C")
      check_c_compiler_flag("-fprofile-instr-generate" PROFILE_INSTR_GENERATE_DETECTED)
      check_c_compiler_flag("-fcoverage-mapping" COVERAGE_MAPPING_DETECTED)
    elseif(${lang} STREQUAL "CXX")
      check_cxx_compiler_flag("-fprofile-instr-generate" PROFILE_INSTR_GENERATE_DETECTED)
      check_cxx_compiler_flag("-fcoverage-mapping" COVERAGE_MAPPING_DETECTED)
    elseif(${lang} STREQUAL "Fortran")
      check_fortran_compiler_flag("-fprofile-instr-generate" PROFILE_INSTR_GENERATE_DETECTED)
      check_fortran_compiler_flag("-fcoverage-mapping" COVERAGE_MAPPING_DETECTED)
    else()
      unset(PROFILE_INSTR_GENERATE_DETECTED)
      unset(COVERAGE_MAPPING_DETECTED)
    endif()

    if(PROFILE_INSTR_GENERATE_DETECTED AND COVERAGE_MAPPING_DETECTED)
      set(CodeCov_${lang}_FLAGS_INTERNAL
        "-g" "-O0" "-fprofile-instr-generate" "-fcoverage-mapping")
      set(CodeCov_${lang}_LINK_FLAGS_INTERNAL
        "-fprofile-instr-generate" "-fcoverage-mapping")
    else()
        unset(CodeCov_${lang}_FLAGS_INTERNAL)
        unset(CodeCov_${lang}_LINK_FLAGS_INTERNAL)
    endif()
  else()
    unset(CodeCov_${lang}_FLAGS_INTERNAL)
    unset(CodeCov_${lang}_LINK_FLAGS_INTERNAL)
  endif()

  set(CodeCov_${lang}_FLAGS "${CodeCov_C_FLAGS_INTERNAL}" CACHE STRING
      "C compiler flags for code coverage.")
  set(CodeCov_${lang}_LINK_FLAGS "${CodeCov_C_LINK_FLAGS_INTERNAL}" CACHE STRING
      "These flags will be used when a target with coverage is linked.")
  mark_as_advanced(CodeCov_${lang}_FLAGS CodeCov_${lang}_LINK_FLAGS)

  if(CMAKE_${lang}_COMPILER_ID STREQUAL "GNU")
    _codecov_gnu_setup()
  else()
    message(FATAL_ERROR "code coverage is not implemented for CMAKE_${lang}_COMPILER_ID")
  endif()

  if(CodeCov_${lang}_FLAGS AND CodeCov_${lang}_LINK_FLAGS)
    set(CodeCov_${lang}_IS_INITIALIZED TRUE PARENT_SCOPE)
  endif()
endfunction()

function(add_coverage_target target lang)
  if(NOT CodeCov_${lang}_IS_INITIALIZED)
    enable_coverage(${lang})
  endif()

  target_compile_options(${target} PRIVATE ${CodeCov_${lang}_FLAGS})
  set_property(TARGET ${target}
    PROPERTY LINK_FLAGS ${CodeCov_${lang}_LINK_FLAGS})
endfunction()

function(add_coverage_run name command)
  if(CMAKE_HOST_UNIX)
    set(failsafe_command
      ${command} ${ARGN} > /dev/null ||
        ${CMAKE_COMMAND} -E echo "Coverage run returned non-zero exit code")
  elseif(CMAKE_HOST_WIN32)
    set(failsafe_command
      ${command} ${ARGN} > NUL ||
        ${CMAKE_COMMAND} -E echo "Coverage run returned non-zero exit code")
  else()
    message(
      WARNING "Unknown host system \"${CMAKE_HOST_SYSTEM_NAME}\",
        coverage runs that fail may break whole coverage record.")
    set(failsafe_command ${command} ${ARGVN})
  endif()

  add_custom_target(${name} COMMAND ${failsafe_command})

  add_dependencies(${name} codecov_prerun)
  add_dependencies(codecov_postrun ${name})
endfunction()
