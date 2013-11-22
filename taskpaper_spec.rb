require_relative 'taskpaper.rb'

describe Taskpaper do
  context "when opening a taskpaper file" do
    subject { Taskpaper.open('example.taskpaper') }
    
    it { should be_kind_of Taskpaper::DataFile }

    its(:project_count) { should == 2 }
    its(:task_count)    { should == 8 }
    its(:comment_count) { should == 2 }
  end

  describe Taskpaper::Line do
    subject { Taskpaper::Line }

    it "accepts one text argument" do
      -> { subject.new('Some text', 'invalid argument') }.should raise_error
    end

    describe ".factory" do
      context "with a project line" do
        it "returns a Project" do
          subject.factory('A project:').class.should == Taskpaper::Project
        end
      end

      context "with a task line" do
        it "returns a Task" do
          subject.factory('- A task').class.should == Taskpaper::Task
        end
      end

      context "with a comment line" do
        it "returns a Comment" do
          subject.factory('A comment').class.should == Taskpaper::Comment
        end
      end
    end

    describe "#project?" do
      it "is a project" do
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
        lines.each { |line| subject.new(line).should be_project, line }
      end

      it "is not a project" do
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
        lines.each { |line| subject.new(line).should_not be_project, line }
      end
    end

    describe "#task?" do
      it "is a task" do
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
        lines.each { |line| subject.new(line).should be_task, line }
      end

      it "is not a task" do
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
        lines.each { |line| subject.new(line).should_not be_task, line }
      end
    end

    describe "#comment?" do
      it "is a comment" do
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
        lines.each { |line| subject.new(line).should be_comment, line }
      end

      it "is not a comment" do
        lines = [
          "- This is a task, not a comment",
          "\t- This is a task, not a comment",
          "This is a project, not a comment:",
          "\tThis is a project, not a comment:",
          "\t\tThis is a project, not a comment:",
        ]
        lines.each { |line| subject.new(line).should_not be_comment, line }
      end
    end

    describe "#regex" do
      it "returns PROJECT" do
        subject.new("A project:").regex.should == Taskpaper::Line::PROJECT
      end

      it "returns TASK" do
        subject.new("- A task").regex.should == Taskpaper::Line::TASK
      end
    end
  end

  describe Taskpaper::Line::Parser do
    subject { Taskpaper::Line::Parser }

    describe ".extract_title" do
      it "extracts project titles" do
        titles = [
          { text: 'A project : @the @tags', expectation: 'A project' },
          { text: "\t\tA project:",         expectation: 'A project' },
          { text: "\t\tA @project:",        expectation: 'A @project' },
        ]
        titles.each do |title|
          line = Taskpaper::Line.new(title[:text])
          subject.extract_title(line).should == title[:expectation]
        end
      end

      it "extracts task titles" do
        titles = [
          { text: '- A task @with @tags',  expectation: 'A task' },
          { text: "\t\t- A task:",         expectation: 'A task:' },
          { text: "\t- @the tags @at_end", expectation: '@the tags' },
        ]
        titles.each do |title|
          line = Taskpaper::Line.new(title[:text])
          subject.extract_title(line).should == title[:expectation]
        end
      end

      it "extracts comment titles" do
        titles = [
          { text: '   A comment',                expectation: 'A comment' },
          { text: "\t\t\s\sA comment:  ",        expectation: 'A comment:' },
          { text: "A comment @with @tags",       expectation: 'A comment' },
          { text: "A comment @tags not @at_end", expectation: 'A comment @tags not' },
        ]
        titles.each do |title|
          line = Taskpaper::Line.new(title[:text])
          subject.extract_title(line).should == title[:expectation]
        end
      end
    end

    describe ".detect_indent" do
      it "detects the indent" do
        titles = [
          { text: 'No indent here',  expectation: 0 },
          { text: "\tOne indent",    expectation: 1 },
          { text: "\t\tTwo indents", expectation: 2 }
        ]
        titles.each do |title|
          line = Taskpaper::Line.new(title[:text])
          subject.detect_indent(line).should == title[:expectation]
        end
      end
    end

    describe ".parse_tags" do
      subject { Taskpaper::Line::Parser.parse_tags("One @line with @tag(values) @and(other values) @hey") }

      its(:length) { should == 4 }
    end

    describe ".parse" do
      it "extracts the line components" do
        line = double('line')

        line.stub(:text).and_return('A line')
        subject.should receive(:extract_title).with(line).and_return('Extract title')
        subject.should receive(:parse_tags).with(line.text).and_return('Parse tags')
        subject.should receive(:detect_indent).with(line).and_return('Detect indent')

        subject.parse(line).should include(
          text:   'A line',
          title:  'Extract title',
          tags:   'Parse tags',
          indent: 'Detect indent',
        )
      end
    end
  end

  describe Taskpaper::DataFile do
    subject(:file) { Taskpaper::DataFile.new(File.read('example.taskpaper')) }

    describe ".line" do
      it "returns the right line" do
        file.line(2).text.should == "\t- @first thing today: read @email"
      end
    end

    describe ".to_s" do
      it "outputs the entire file" do
        "#{subject.to_s}\n".should == File.read('example.taskpaper')
      end
    end
  end
end
