module Taskpaper

  def self.factory(path)
    contents = File.read path
    DataFile.new contents, LineParser.new
  end

  class LineParser
    PROJECT = /\A\t*[^-\s](.+):( ((@[^\s]+\s+)+)?@[^\s]+)?\Z/
    TASK    = /\A\t*-\s(.*)\Z/
    TAG     = /(@(\S+)\((.*?)\)|@(\S+))/

    attr_accessor :line

    def is_project?
      line =~ PROJECT
    end

    def is_task?
      line =~ TASK
    end

    def is_comment?
      !is_project? && !is_task?
    end

    def extract_title(type)
      line[type, 1]
    end

    def detect_indent
      line[/\t*/].length
    end

    def parse_tags(line)
      line.scan(TAG).map { |args| Tag.new(*args.compact) }
    end

    def parse
      tags = parse_tags(line)
      if is_project?
        Project.new line, extract_title(PROJECT), tags
      elsif is_task?
        Task.new line, extract_title(TASK), tags
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
