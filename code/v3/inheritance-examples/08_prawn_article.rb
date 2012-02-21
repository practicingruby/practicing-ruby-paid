require "prawn"

module Prawn
  class Article < Document
    include Measurements

    def build(&block)
      instance_eval(&block)
    end

    def save_as(filename)
      render_file(filename)
    end

    def h1(contents)
      text(contents, :size => 24)
      move_down in2pt(0.3)
    end

    def h2(contents)
      text(contents, :size => 16)
      move_down in2pt(0.2)
    end

    def para(contents)
      text(contents)
      move_down in2pt(0.1)
    end
  end
end

=begin
module Prawn
  class Article
    def initialize
      self.document = Prawn::Document.new 
      document.extend(Prawn::Measurements)
    end

    def build(&block)
      instance_eval(&block)
    end

    def save_as(filename)
      document.render_file(filename)
    end

    def h1(contents)
      text(contents, :size => 24)
      move_down in2pt(0.3)
    end

    def h2(contents)
      text(contents, :size => 16)
      move_down in2pt(0.2)
    end

    def para(contents)
      text(contents)
      move_down in2pt(0.1)
    end

    def method_missing(id, *args, &block)
      document.send(id, *args, &block)
    end

    private

    attr_accessor :document
  end
end
=end

=begin
module Prawn
  class Article
    module DocumentExtensions
      def h1(contents)
        text(contents, :size => 24)
        move_down in2pt(0.3)
      end

      def h2(contents)
        text(contents, :size => 16)
        move_down in2pt(0.2)
      end

      def para(contents)
        text(contents)
        move_down in2pt(0.1)
      end
    end

    def initialize
      self.document = Prawn::Document.new 
      document.extend(Prawn::Measurements)
      document.extend(DocumentExtensions)
    end

    def build(&block)
      document.instance_eval(&block)
    end

    def save_as(filename)
      document.render_file(filename)
    end

    private

    attr_accessor :document
  end
end
=end


article = Prawn::Article.new

article.build do
  font "Times-Roman"

  h1 "Yaaay"
 
  para %{
   Awww yeaaaah.
  }

  h2 "AAAAAAAA NNDFF"

  para "Blah blah blah"
  para "fap fap fap"
end

article.save_as("test.pdf")

`open test.pdf`
