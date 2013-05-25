module Taskpaper

  def self.factory(path)
    contents = File.read path
    DataFile.new contents, RawLineParser.new
  end

  class RawLineParser
    TASK    = /\A\t*-\s+([^\s]+)\Z/
    PROJECT = /\A\t*[^-\s](.+):( ((@[^\s]+\s+)+)?@[^\s]+)?\Z/

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

    def execute(line)
    end
  end

  class DataFile
    attr_accessor :raw_content

    def initialize(contents, parser)
      @raw_content = contents
      @lines = []

      contents.each_line do |line|
        @lines << parser.execute(line)
      end
    end
  end

  Line = Struct.new(:text, :title, :tags, :father, :children) do
    attr_accessor :text, :title, :tags, :father, :children
  end

  class Project < Line
  end

  class Task < Line
  end

  class Comment < Line
  end

  class Tag
  end
end
