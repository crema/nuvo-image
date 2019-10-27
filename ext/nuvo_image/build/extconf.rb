require 'mkmf'

dir = __dir__

puts `cmake .. -DCMAKE_INSTALL_PREFIX=#{File.join(dir, '../')}`
$makefile_created = true
