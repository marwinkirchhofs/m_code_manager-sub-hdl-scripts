#!/usr/bin/env python3

# helper script to give makefiles a "quasi" json api
# Since make doesn't have a native json api, it needs to call something via 
# $(shell ...). And this project already uses the python json package anyway, so 
# this method is convenient and does not create any new requirements.
# usage:
# $1 - json file to read from
# $2 - name of the field to read

import sys
import json

def get_json_var_from_object_file(json_file, var_name):
    """get the field 'var_name' from the json OBJECT file json_file (probably 
    won't work with a json array config file)
    """
    with open(json_file, 'r') as f_in:
        d_data = json.load(f_in)
    return d_data[var_name]

if __name__ == "__main__":
    json_file =     sys.argv[1]
    var_name =      sys.argv[2]
    print(get_json_var_from_object_file(json_file, var_name))

