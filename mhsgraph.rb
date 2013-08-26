require 'sinatra/base'
require 'json'
require 'sequel'

DB = Sequel.connect 'sqlite://database.db'
$students = JSON.load(File.read('students.mhs'))
$students = $students.each_with_index.map do |n, i|
  n['id'] = i + 1
  n
end

class MHSGraph < Sinatra::Base
  set :sessions, true

  helpers do
    def full_name(name_hash)
      [
        name_hash['first_name'],
        name_hash['last_name']
      ].map(&:capitalize).join ' '
    end
  end

  get '/' do
    @students = $students
    erb :form
  end

  post '/submit' do
    puts "Receeived submissions.."
    # First, figure out who is submitting.
    user_first = params['first_name'].downcase
    user_last = params['last_name'].downcase

    user_nick = user_first.capitalize + ' ' + user_last[0].capitalize + '.'

    user = $students.find do |s|
      s['first_name'] == user_first && s['last_name'] == user_last
    end

    if !user
      puts "Couldn't find that user...."
      return "Unknown user.  You probably spelled your name wrong."
    end

    user_id = user['id']

   # Now create all the relations from the User's
   # survey.

   student_ids = []
   params.map do |k, v|
     if v != nil && k =~ /student-(\d+)/
       puts "found a match"
       student_ids << $1.to_i
     end
   end

   student_ids.each do |id|
     qresult = $students.select {|s| s['id'] == id }
     student_first = qresult.first['first_name'].capitalize
     student_last = qresult.first['last_name'].capitalize
     student_nick = student_first + ' ' + student_last[0] + '.'
     # student_name = student["name"]
     # TODO: This needs to be able to handle dup names.
     DB[:relations].insert({
      :start_id => user_id,
      :end_id => user_id,
      :start_name => user_nick,
      :end_name => student_nick
     })
   end

   build_graph
   redirect '/graph.png'
  end

  get '/graph.png' do
    content_type 'image/png'
    File.read('./graph.png')
  end

  def build_graph
    puts "Rebuilding graph..."
    graph =<<EOS
	graph G {
	  sep="+10, 10";
	  splines=curved;
	  overlap=scale;
EOS

    DB[:relations].all.each do |rel|
      graph << "  \"#{rel[:start_name]}\" -- \"#{rel[:end_name]}\""
    end
    graph << "}"
    File.open('mhs.dot', 'w') { |f| f.puts graph }
    `neato -Tpng mhs.dot -o graph.png`
  end
end
