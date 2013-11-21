module Taskpaper
  class Line
    TAGS_AT_END = '(\s((@[^\s]+\s+)+)?@[^\s]+)?'
    PROJECT     = /\A\t*(?!-\s)([^\s].*?):#{TAGS_AT_END}\Z/
    TASK        = /\A\t*-\s(.*?)#{TAGS_AT_END}\Z/

    attr_reader :text

    def initialize(text)
      @text = text
    end

    def project?
      !!(text =~ PROJECT)
    end

    def task?
      !!(text =~ TASK)
    end

    def comment?
      !project? && !task?
    end

    def regex
      return PROJECT if project?
      return TASK    if task?
    end

    module Parser
      TAG = /(@(\S+)\((.*?)\)|@(\S+))/

      def self.extract_title(line)
        if line.comment?
          line.text[/\A(\t(?!-\s)|[\t\s])*(.*?)#{TAGS_AT_END}\Z/, 2].strip
        else
          line.text[line.regex, 1].strip
        end
      end

      def self.detect_indent(line)
        line.text[/\t*/].length
      end

      def self.parse_tags(text)
        text.scan(TAG).collect { |args| Tag.new(*args.compact) }
      end

      def self.parse(line)
        { 
          text:   line.text, 
          title:  extract_title(line), 
          tags:   parse_tags(line.text), 
          indent: detect_indent(line) 
        }
      end
    end
  end

  def Line.factory(text)
    line = new(text)
    args = Line::Parser.parse(line)

    return Project.new args if line.project?
    return Task.new args    if line.task?
    return Comment.new args
  end

  class ParsedLine
    attr_reader :text, :title, :indent, :tags

    def initialize(args)
      args.each do |arg, val|
        instance_variable_set("@#{arg}", val)
      end
    end

    def type
      self.class
    end

    def to_s
      text
    end
  end

  class Project < ParsedLine; end
  class Task    < ParsedLine; end
  class Comment < ParsedLine; end

  Tag = Struct.new(:tag, :title, :value) do
    attr_reader :tag, :title, :value
  end

  class DataFile
    include Enumerable
    attr_reader :lines

    def initialize(contents)
      @lines = contents.split(/\n/).map { |line| Line.factory(line) }
    end

    def project_count
      count Project
    end

    def task_count
      count Task
    end

    def comment_count
      count Comment
    end

    def line(number)
      lines[number - 1]
    end

    def each(&block)
      lines.each { |line| block.call line }
    end

    def to_s
      lines.join("\n")
    end

    private
      def count(type)
        lines.inject(0) do |total, line| 
          total = total + 1 if line.type == type
          total
        end
      end
  end
  
  def self.open(path)
    contents = File.read path
    DataFile.new contents
  end
end
