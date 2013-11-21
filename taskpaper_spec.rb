require_relative 'taskpaper.rb'

describe Taskpaper do
  context "when reading a text file" do
    it "returns a DataFile object" do
      file = Taskpaper.open('example.taskpaper')
      file.should be_kind_of Taskpaper::DataFile
    end
  end

  describe Taskpaper::Line do
    describe "#project?" do
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
          lines.each { |line| Taskpaper::Line.new(line).should be_project }
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
          lines.each { |line| Taskpaper::Line.new(line).should_not be_project }
        end
      end
    end

    describe "#task?" do
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
          lines.each { |line| Taskpaper::Line.new(line).should be_task }
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
          lines.each { |line| Taskpaper::Line.new(line).should_not be_task }
        end
      end
    end
  end

  describe Taskpaper::Line::Parser do
    describe "#parse_tags" do
      subject { Taskpaper::Line::Parser.parse_tags("One @line with @tag(values) @and(other values) @hey") }

      its(:length) { should == 4 }
    end
  end

  describe Taskpaper::DataFile do
    context "when an object is created" do
      subject { Taskpaper.open('example.taskpaper') }

      its(:project_count) { should == 2 }
      its(:task_count)    { should == 7 }
      its(:comment_count) { should == 1 }
    end
  end
end
