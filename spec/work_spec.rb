require_relative '../lib/work.rb'

require 'benchmark'

RSpec.describe '.work' do
  before do
    File.write('result.json', '')
    File.write('data.txt',
'user,0,Leida,Cira,0
session,0,0,Safari 29,87,2016-10-23
session,0,1,Firefox 12,118,2017-02-27
session,0,2,Internet Explorer 28,31,2017-03-28
session,0,3,Internet Explorer 28,109,2016-09-15
session,0,4,Safari 39,104,2017-09-27
session,0,5,Internet Explorer 35,6,2016-09-01
user,1,Palmer,Katrina,65
session,1,0,Safari 17,12,2016-10-21
session,1,1,Firefox 32,3,2016-12-20
session,1,2,Chrome 6,59,2016-11-11
session,1,3,Internet Explorer 10,28,2017-04-29
session,1,4,Chrome 13,116,2016-12-28
user,2,Gregory,Santos,86
session,2,0,Chrome 35,6,2018-09-21
session,2,1,Safari 49,85,2017-05-22
session,2,2,Firefox 47,17,2018-02-02
session,2,3,Chrome 20,84,2016-11-25
')

    work('data.txt')
  end

  let!(:expected_result) do
    JSON.parse('{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}')
  end


  it 'produces correct result' do
    actual_result = JSON.parse(File.read('result.json'))

    aggregate_failures do
      expected_result.keys.each do |key|
        expect(actual_result[key]).to eq(expected_result[key])
      end
    end
  end

  shared_examples_for 'performance spec' do |input_size, mem_budget, time_budget|
    context "when the input size is #{input_size}" do
      before { create_sample_file(input_size.to_s, input_size) }

      let!(:benchmark_data) { measure_work(input_size.to_s) }

      it 'does not exceed time budget' do
        expect(benchmark_data[:time]).to be <= time_budget
      end

      it 'does not exceed memory budget' do
        expect(benchmark_data[:mem]).to be <= mem_budget
      end
    end
  end

  describe 'memory consumption' do
    it_behaves_like 'performance spec', 10_000, 30, 0.5
    it_behaves_like 'performance spec', 50_000, 30, 1
    it_behaves_like 'performance spec', 100_000, 30, 2
    
    context 'prod data set', :slow do
      let!(:benchmark_data) { measure_work('data_large.txt') }
      let(:time_budget) { 20 }
      let(:mem_budget) { 70 }

      it 'does not exceed time budget' do
        expect(benchmark_data[:time]).to be <= time_budget
      end

      it 'does not exceed memory budget' do
        expect(benchmark_data[:mem]).to be <= mem_budget
      end
    end
  end

  def create_sample_file(name, size)
    return if File.exists?(name)

    `tail -n #{size} data_large.txt > #{name}`
  end

  def measure_work(file_name)
    memory = nil
    time = Benchmark.measure do
      memory = work(file_name)
    end

    { time: time.real, mem: memory }
  end
end
