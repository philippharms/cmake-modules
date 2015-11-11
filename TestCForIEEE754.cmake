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

if(NOT DEFINED _CMAKE_C_IEEE754_FLOATS)
  message(STATUS "Check whether C compiler supports IEEE 754 floats")
  try_compile(_CMAKE_C_IEEE754_FLOATS ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/cmake/modules/TestCForIEEE754.c)
  if(_CMAKE_C_IEEE754_FLOATS)
    message(STATUS "Check whether C compiler supports IEEE 754 floats - found")
    set(CMAKE_C_IEEE754_FLOATS 1 CACHE INTERNAL
      "Does the C compiler support IEEE 754 floats.")
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
      "Determining if the C compiler supports IEEE 754 floats passed with "
      "the following output:\n${OUTPUT}\n\n")
  else()
    message(STATUS "Check whether C compiler supports IEEE 754 floats - not found")
    set(CMAKE_C_IEEE754_FLOATS 0 CACHE INTERNAL
      "Does the C compiler support IEEE 754 floats.")
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
      "Determining if the C compiler supports IEEE 754 floats failed with "
      "the following output:\n${OUTPUT}\n\n")
  endif()
endif()
