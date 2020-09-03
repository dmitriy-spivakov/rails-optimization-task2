require_relative 'work'
require 'ruby-prof'

RubyProf.measure_mode = RubyProf::MEMORY
result = RubyProf.profile do
  work('prof_file')
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
