module Taskpaper

  def self.factory(path)
    contents = File.read path
    DataFile.new contents, LineParser.new
  end

  class LineParser
    PROJECT        = /\A\t*[^-\s](.+):( ((@[^\s]+\s+)+)?@[^\s]+)?\Z/
    TASK           = /\A\t*-\s(.*)\Z/
    TAG_WITH_VALUE = /(@([^\s]+)\((.+?)\))/
    TAG            = /(@([^\s]+))/

    def initialize(&callback)
      @callback = callback if block_given?
    end

    def is_project? line
      line =~ PROJECT
    end

    def is_task? line
      line =~ TASK
    end

    def is_comment? line
      !is_comment?(line) && !is_task?(line)
    end

    def title(line, type)
      line[type, 1]
    end

    def detect_indent line
      line[/\t*/].length
    end

    def parse_tags(line)
      tags = []
      if line =~ TAG_WITH_VALUE
        line.scan(TAG_WITH_VALUE) do |args|
          tags << Tag.new(*args)
        end
      elsif line =~ TAG
        line.scan(TAG) do |args|
          tags << Tag.new(*args)
        end
      end
      tags
    end

    def parse(line)
      tags = parse_tags(line)
      if is_project? line
        Project.new line, title(line, PROJECT), tags
      elsif is_task? line
        Task.new line, title(line, TASK), tags
      else
        Comment.new line, line.strip, tags
      end
    end
  end

  class DataFile
    include Enumerable
    attr_reader :lines

    def initialize(contents, parser)
      @lines = []

      contents.each_line do |line|
        @lines << parser.parse(line)
      end
    end

    def projects
      2
    end

    def each(&block)
      lines.each { |line| block.call line }
    end
  end

  Line = Struct.new(:text, :title, :tags, :children) do
    attr_accessor :text, :title, :tags, :children
  end

  class Project < Line; end
  class Task    < Line; end
  class Comment < Line; end

  Tag = Struct.new(:tag, :title, :value)
end
