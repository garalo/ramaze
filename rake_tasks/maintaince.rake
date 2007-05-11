desc "add copyright to all .rb files in the distribution"
task 'add-copyright' do
  puts "adding copyright to files that don't have it currently"
  Dir['{lib,test}/**/*{.rb}'].each do |file|
    next if file =~ /_darcs/
    lines = File.readlines(file).map{|l| l.chomp}
    unless lines.first(COPYRIGHT.size) == COPYRIGHT
      puts "fixing #{file}"
      File.open(file, 'w+') do |f|
        (COPYRIGHT + ["\n"] + lines).each do |line|
          f.puts(line)
        end
      end
    end
  end
end

desc "doc/README to html"
Rake::RDocTask.new('readme2html-build') do |rd|
  rd.options = %w[
    --quiet
    --opname readme.html
  ]

  rd.rdoc_dir = 'readme'
  rd.rdoc_files = ['doc/README']
  rd.main = 'doc/README'
  rd.title = "Ramaze documentation"
end

desc "doc/README to doc/README.html"
task 'readme2html' => ['readme-build', 'readme2html-build'] do
  cp('readme/files/doc/README.html', 'doc/README.html')
  rm_rf('readme')
end

desc "generate doc/TODO from the TODO tags in the source"
task 'todolist' do
  list = `rake todo`
  tasks = {}
  current = nil

  list.split("\n")[2..-1].each do |line|
    if line =~ /TODO/ or line.empty?
    elsif line =~ /^vim/
      current = line.split[1]
      tasks[current] = []
    else
      tasks[current] << line
    end
  end

  lines = tasks.map{ |name, items| [name, items, ''] }.flatten
  lines.pop

  File.open(File.join('doc', 'TODO'), 'w+') do |f|
    f.puts "This list is programmaticly generated by `rake todolist`"
    f.puts "If you want to add/remove items from the list, change them at the"
    f.puts "position specified in the list."
    f.puts
    f.puts(lines)
  end
end

desc "remove those annoying spaces at the end of lines"
task 'fix-end-spaces' do
  Dir['{lib,spec}/**/*.rb'].each do |file|
    next if file =~ /_darcs/
    lines = File.readlines(file)
    new = lines.dup
    lines.each_with_index do |line, i|
      if line =~ /\s+\n/
        puts "fixing #{file}:#{i + 1}"
        p line
        new[i] = line.rstrip
      end
    end

    unless new == lines
      File.open(file, 'w+') do |f|
        new.each do |line|
          f.puts(line)
        end
      end
    end
  end
end

desc "Compile the doc/README from the parts of doc/readme"
task 'readme-build' do
  require 'enumerator'

  chapters = [
    'About Ramaze',         'introduction',
    'Features Overview',    'features',
    'Basic Principles',     'principles',
    'Installation',         'installing',
    'Getting Started',      'getting_started',
    'A couple of Examples', 'examples',
    'How to find Help',     'getting_help',
    'Appendix',             'appendix',
    'And thanks to...',     'thanks',
  ]

  File.open('doc/README', 'w+') do |readme|
    readme.puts COPYRIGHT.map{|l| l[1..-1]}, ''

    chapters.each_slice(2) do |title, file|
      file = File.join('doc', 'readme_chunks', "#{file}.txt")
      chapter = File.read(file)
      readme.puts "= #{title}", '', chapter
      readme.puts '', '' unless title == chapters[-2]
    end
  end
end

task 'tutorial2html' do
  require 'bluecloth'

  basefile = File.join('doc', 'tutorial', 'todolist')

  content = File.read(basefile + '.txt')

  html = BlueCloth.new(content).to_html

  wrap = %{
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html>
    <head>
      <title>Ramaze Tutorial: Todolist</title>
      <style>
        body {
          background: #eee;
        }
        code {
          background: #ddd;
        }
        pre code {
          background: #ddd;
          width: 70%;
          display: block;
          margin: 1em;
          padding: 0.7em;
          overflow: auto;
        }
      </style>
      <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    </head>
    <body>
      #{html}
    </body>
  </html>
  }.strip

  File.open(basefile + '.html', 'w+'){|f| f.puts(wrap) }
end

task 'authors' do
  changes = `darcs changes`
  authors = []
  mapping = {}
  author_map = {
    'm.fellinger@gmail.com' => 'Michael Fellinger',
    'manveru@weez-int.com'  => 'Michael Fellinger',
    'clive@crous.co.za'     => 'Clive Crous'
  }
  changes.split("\n").grep(/^\w/).each do |line|
    splat  = line.split
    author = splat[6..-1]
    email  = author.pop
    email.gsub!(/<(.*?)>/, '\1')
    name   = author.join(' ')
    name   = author_map[email] if name.empty?
    mapping[name] = email
  end

  max = mapping.map{|k,v| k.size}.max

  File.open('doc/AUTHORS', 'w+') do |fp|
    fp.puts("Following persons have contributed to Ramaze:")
    fp.puts
    mapping.sort_by{|k,v| v}.each do |name, email|
      fp.puts("#{name.ljust(max)} - #{email}")
    end
  end
end
