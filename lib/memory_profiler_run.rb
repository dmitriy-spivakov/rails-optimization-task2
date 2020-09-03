require_relative 'work'

require 'memory_profiler'


def profile
  report = MemoryProfiler.report do
    work('prof_file')
  end

  report.pretty_print(scale_bytes: true) 
end

profile
