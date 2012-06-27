str = File.read("/home/kandie/Workspace/Projects/grind/test/fixture/my_file.txt")
re = /([A-Z]{1}[a-z]{2} [0-9]+ [0-9]{2}:[0-9]{2}:[0-9]{2} )+/
10000000.times do
  re.match(str)
  re.match(str)
end