
package require fileutil

# find files by wildcard recursively into a directory (basically the recursive 
# extension of `glob`)
# you can pass parameters in exactly the same way as you would to glob
# thanks to https:
# //stackoverflow.com/questions/429386/tcl-recursively-search-subdirectories-to-source-all-tcl-files
# (turns out that vivado 2019.1 has fileutil accessible, that's old enough for 
# me
proc mcm_util_find_files {basedir pattern} {
    set list_files []
    foreach file [fileutil::findByPattern $basedir $pattern] {
        lappend list_files $file
    }
    return $list_files
}
