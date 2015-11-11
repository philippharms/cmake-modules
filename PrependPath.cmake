function(prepend_path OUTPUT_LIST PATH_NAME FILE_LISTS)
  unset(PREPEND_PATH_TEMP)

  foreach(IN_FILE IN LISTS ${FILE_LISTS})
    list(APPEND PREPEND_PATH_TEMP "${PATH_NAME}/${IN_FILE}")
  endforeach()

  set(${OUTPUT_LIST} ${PREPEND_PATH_TEMP} PARENT_SCOPE)
endfunction()
