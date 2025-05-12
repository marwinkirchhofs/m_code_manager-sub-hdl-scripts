#!/usr/bin/env bash

ifndef _UTIL_MK_
_UTIL_MK_ := 1

# how does that work? `make -n` is a dry-run, which only prints one line with 
# either "Nothing to be done" or "is up to date" in it if target is up-to-date.  
# Filtering that line with grep actually returns 1 for the up-to-date case, and 
# 0 otherwise, because in the up-to-date case grep apparently is sad that it has 
# nothing to print at all.
# !! make sure to only use that with lazy set (`=`), not immediate set (`:=`), 
# it apparently stalls the makefile with immediate set.
fun_check_target_out_of_date = \
		$(shell make -n $(1) | \
		grep -v "Nothing to be done" | grep -v "is up to date" 1>/dev/null 2>&1 && echo "true")

endif # _UTIL_MK_
