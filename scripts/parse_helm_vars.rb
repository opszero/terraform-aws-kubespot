#!/usr/bin/ruby

require "yaml"

HELM_VARS = ARGV[0]
OUT_FILE = ARGV[1]
vars = {  }
HELM_VARS.split(",").each do |var|
  key, value = var.split("=")
  vars[key] = value
end
File.open(OUT_FILE, "w") do |f|
  f.write(vars.to_yaml)
end
