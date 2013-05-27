require_relative 'taskpaper.rb'

describe Taskpaper do
  context "when reading a text file" do
    it "returns a DataFile object" do
      file = Taskpaper.factory('example.taskpaper')
      file.should be_kind_of Taskpaper::DataFile
    end
  end

  describe Taskpaper::LineParser do
    let(:parser) { Taskpaper::LineParser.new }

    describe "#is_project?" do
      context "with valid project lines" do
        it "asserts valid projects" do
          lines = [
            "Home tasks:",
            "\tCleaning:",
            "\t\tOther:",
            "Room organization: @weekly",
            "Drawings:",
            "\tPaintings: @daily @art",
            "\tPaper Drawings:",
            "Weird Project: @tag1  @tag2 @tag3"
          ]
          lines.each do |line|
            parser.is_project?(line).should_not be_nil
          end
        end
      end

      context "with invalid project lines" do
        it "doesn't assert invalid projects" do
          lines = [
            "Home tasks: ",
            "\t Cleaning:",
            "\t\tOther: ",
            "Room organization: @weekly mess",
            "- Drawings:",
            "\tPaintings: @daily ",
            "\tPaper Drawings: @one two @three",
            "\tAnother: @one @two @three ",
            "Comment line",
            "New line project:\n\n"
          ]
          lines.each do |line|
            parser.is_project?(line).should be_nil
          end
        end
      end
    end

    describe "#is_task" do
      context "with valid task lines" do
        it "asserts valid tasks" do
          lines = [
            "- Home tasks",
            "\t- Cleaning:",
            "\t\t- Other",
            "- Room organization @weekly",
            "\t\t\t- Drawings @daily everyday",
            "\t- Paintings: @daily @art",
            "\t- @many Paper Drawings @everyday",
            "- Weird task: @tag1  @tag2 @tag3"
          ]
          lines.each do |line|
            parser.is_task?(line).should_not be_nil, "#{line} should be a task"
          end
        end
      end

      context "with invalid task lines" do
        it "doesn't assert invalid tasks" do
          lines = [
            "Home tasks: ",
            "\t Cleaning:",
            "\t\tOther: ",
            "Room organization: @weekly mess",
            "-Drawings:",
            "\tPaintings: @daily ",
            "\tPaper Drawings: @one two @three",
            "\tAnother: @one @two @three ",
            "Comment line",
            "New line task:\n\n"
          ]
          lines.each do |line|
            parser.is_task?(line).should be_nil
          end
        end
      end
    end

    describe "#parse_tags" do
      subject { parser.parse_tags "One @line with @tag(values) @and(other values)" }

      its(:length) { should == 3 }
    end
  end

  describe Taskpaper::DataFile do
    context "when an object is created" do
      subject { Taskpaper.factory('example.taskpaper') }

      its(:projects) { should == 2 }
    end
  end
end
