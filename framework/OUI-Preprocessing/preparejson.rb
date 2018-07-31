#!/usr/bin/env ruby

require 'json'

old_basename = "OUItoCompany"
new_basename = "OUItoCompany2Level"
other_basename = "OUItoCompanyShort"

output_old = {}
output_new = {}
output_other = {}
File.open("nmap-mac-prefixes.txt") do |file|
	file.each do |line|
		prefix = line[0...6].downcase
		company = line [6..-1].strip
		
		uprefix = prefix.upcase
		output_old["#{uprefix[0..1]}:#{uprefix[2..3]}:#{uprefix[4..5]}"] = company
		
		firstkey = prefix[0..1]
		secondkey = prefix[2..5]
		output_new[firstkey] = {} if output_new[firstkey].nil?
		output_new[firstkey][secondkey] = company
		
		output_other[prefix] = company
	end	
end

def write_file(name, hash) 
	File.open(name + "_pretty.json",'w') do |file|
		file.puts(JSON.pretty_generate(hash))
	end
	File.open(name + ".json",'w') do |file|
		file.puts(JSON.generate(hash))
	end
	
	%x[plutil -convert binary1 #{name}.json -o #{name}.plist]
	%x[gzip -9 #{name}.json -k]
end

write_file(old_basename, output_old);
write_file(new_basename, output_new);
write_file(other_basename, output_other);

