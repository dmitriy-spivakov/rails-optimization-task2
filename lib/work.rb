# Deoptimized version of homework task
require 'json'
require 'pry'
require 'date'
require 'set'

REPORT_PATH = 'result.json'.freeze

def parse_user(user)
  fields = user.split(',')
  parsed_result = {
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4],
  }
end

def parse_session(session)
  fields = session.split(',')
  parsed_result = {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3],
    'time' => fields[4],
    'date' => fields[5],
  }
end

def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge(block.call(user))
  end
end

def work(file_path)
  unique_browsers = Set.new
  users_counter = 0
  sessions_counter = 0

  current_user = nil
  current_user_sessions = []
  first_record = true

  write_prepend_userstats_key

  IO.readlines(file_path).each do |line|
    if line.start_with?('user')
      first_record = !append_user(current_user, current_user_sessions, first_record)

      current_user = parse_user(line)
      current_user_sessions.clear

      users_counter += 1
    else
      new_session = parse_session(line)
      unique_browsers << new_session['browser'].upcase
      current_user_sessions << new_session
      sessions_counter += 1
    end
  end
  append_user(current_user, current_user_sessions, first_record)
  write_close_userstats_key

  write_totals(users_counter, sessions_counter, unique_browsers)

  write_close_json_payload

  print_mem_usage

  mem_usage
end

def append_user(current_user, current_user_sessions, first_record)
  return false unless current_user

  append_to_report(",\n") unless first_record
  write_to_report(current_user, current_user_sessions)

  true
end

def write_prepend_userstats_key
  append_to_report("{ \"usersStats\": {")
end

def write_to_report(current_user, current_user_sessions)
  user_report = {}

  user_report['sessionsCount'] = current_user_sessions.count

  session_times = current_user_sessions.map { |s| s['time'].to_i }
  user_report['totalTime'] = session_times.sum.to_s + ' min.'
  user_report['longestSession'] = session_times.max.to_s + ' min.'

  user_browsers = current_user_sessions.map { |s| s['browser'].upcase }.sort
  user_report['browsers'] = user_browsers.join(', ')
  
  user_browsers.uniq!
  user_report['usedIE'] = user_browsers.any? { |b| b.match?(/INTERNET EXPLORER/) }
  user_report['alwaysUsedChrome'] = user_browsers.size == 1 && user_browsers.first.match?(/CHROME/)

  user_report['dates'] = current_user_sessions.map {|d| Date.parse(d['date'])}.sort.reverse.map { |d| d.iso8601 } 

  user_key = "#{current_user['first_name']} #{current_user['last_name']}"
  append_to_report({ user_key => user_report }.to_json[1..-2])
end

def write_close_userstats_key
  append_to_report("},\n")
end

def write_totals(users_counter, sessions_counter, unique_browsers)
  append_to_report("\"totalUsers\": #{users_counter},\n")
  append_to_report("\"totalSessions\": #{sessions_counter},\n")
  append_to_report("\"uniqueBrowsersCount\": #{unique_browsers.size},\n")
  append_to_report("\"allBrowsers\": \"#{unique_browsers.sort.join(',')}\"\n")
end

def write_close_json_payload
  append_to_report("}\n")
end

def append_to_report(string)
  File.open(REPORT_PATH, 'a') { |f| f.write(string) }
end

def print_mem_usage
  puts "MEMORY USAGE: %d MB" % (mem_usage)
end

def mem_usage
  `ps -o rss= -p #{Process.pid}`.to_i / 1024
end
