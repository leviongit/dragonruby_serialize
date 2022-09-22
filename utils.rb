def todo!(name, str = "")
  puts "TODO: #{name} #{str}"
end

def notimplemented!(name, str = "")
  raise NotImplementedError, "Not yet implemented: #{name} #{str}"
end
