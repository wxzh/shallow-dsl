require 'fileutils'

# Example 1 - Read File and close
def scan(fileName, beginpos, endpos, fileloc)
  file = File.new(fileName, "r")
  counter = 1
  while (line = file.gets)
    if line =~ /BEGIN_(\w+)/
      throw "Symbol '#{$1}' already defined " + fileName if fileloc[$1]
      fileloc[$1] = fileName
      beginpos[$1] = counter+1
      puts "BEGIN #{$1}: #{beginpos[$1]}"
    end
    if line =~ /END_(\w+)/
      endpos[$1] = counter-1
      puts "END #{$1}: #{endpos[$1]}"
    end
    counter = counter + 1
  end
  file.close
end

def process(file, out, beginpos, endpos, fileloc)
  while (line = file.gets)
    if line =~ /APPLY:\s?(\w+)/
      label = $1
      puts "Processing #{label}"
      #puts "Line before: #{line}"
      if fileloc.has_key?(label) then
        line = line.sub( /linerange=([0-9-]*)/, "linerange=#{beginpos[label]}-#{endpos[label]}" )
        #puts "Line is now 1: #{line}"
        line = line.sub( /\{[^{]*\}/, "{#{fileloc[label]}}" )
        #puts "Line is now 2: #{line}"
      else
        puts "Not found!"
      end
    end
    out.write(line)
  end
  file.close
  out.close
end

fileloc = {}
beginpos = {}
endpos = {}

Dir['../src/*/*.{java,scala}'].each do |file|
  scan(file, beginpos, endpos, fileloc)
end

Dir['../src/*/*/*.{java,scala}'].each do |file|
  scan(file, beginpos, endpos, fileloc)
end

Dir['./code/*'].each do |file|
  scan(file, beginpos, endpos, fileloc)
end

Dir['*.tex'].each do |file|
  #temp = Tempfile.new('compute_positions')
  tempname = "footempfile.txt"
  temp = File.new(tempname, "w")
  process(File.new(file, "r"), temp, beginpos, endpos, fileloc)
  FileUtils.cp(file, "#{file}-old")
  FileUtils.cp(tempname, file)
end

Dir['./sections/*.tex'].each do |file|
  #temp = Tempfile.new('compute_positions')
  tempname = "footempfile.txt"
  temp = File.new(tempname, "w")
  process(File.new(file, "r"), temp, beginpos, endpos, fileloc)
  FileUtils.cp(file, "#{file}-old")
  FileUtils.cp(tempname, file)
end
