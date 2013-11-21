require_relative 'taskpaper.rb'

describe Taskpaper do
  context "when reading a text file" do
    it "returns a DataFile object" do
      file = Taskpaper.open('example.taskpaper')
      file.should be_kind_of Taskpaper::DataFile
    end
  end

  describe Taskpaper::Line do
    it "is instantiated with only one text argument" do
      -> { Taskpaper::Line.new('Some text', 'invalid argument') }.should raise_error
    end

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
          lines.each do |line|
            Taskpaper::Line.new(line).should be_project, line
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
            Taskpaper::Line.new(line).should_not be_project, line
          end
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
          lines.each do |line|
            Taskpaper::Line.new(line).should be_task, line
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
            Taskpaper::Line.new(line).should_not be_task, line
          end
        end
      end
    end

    describe "#comment?" do
      context "with valid comment lines" do
        it "asserts valid comments" do
          lines = [
            "Like a fine wine, really",
            "\tI've got blisters on my fingers!",
            "\t And in the end, the love you take, is equal to the love you make",
            "\t\tAre you a mod or a rocker?",
            "      Never could be any other way   ",
            "      Yesterday, all my troubles seemed so far @away",
            " - I'm a mocker:",
            "Here today: ",
            " Number nine, number nine, number nine, @number @nine @number(nine)"
          ]
          lines.each do |line|
            Taskpaper::Line.new(line).should be_comment, line
          end
        end
      end

      context "with invalid comment lines" do
        it "asserts invalid comments" do
          lines = [
            "- This is a task, not a comment",
            "\t- This is a task, not a comment",
            "This is a project, not a comment:",
            "\tThis is a project, not a comment:",
            "\t\tThis is a project, not a comment:",
          ]
          lines.each do |line|
            Taskpaper::Line.new(line).should_not be_comment, line
          end
        end
      end
    end

    describe "#regex" do
      it "returns the PROJECT regex for a project line" do
        Taskpaper::Line.new("A project:").regex.should == Taskpaper::Line::PROJECT
      end

      it "returns the TASK regex for a task line" do
        Taskpaper::Line.new("- A task").regex.should == Taskpaper::Line::TASK
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
      its(:comment_count) { should == 2 }
    end
  end
end
