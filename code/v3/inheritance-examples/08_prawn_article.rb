require "prawn"

module Prawn
  class Article < Document
    include Measurements

    def h1(contents)
      text(contents, :size => 24)
      move_down in2pt(0.3)
    end

    def h2(contents)
      move_down in2pt(0.1)
      text(contents, :size => 16)
      move_down in2pt(0.2)
    end

    def para(contents)
      text(contents.gsub(/\s+/, " "))
      move_down in2pt(0.1)
    end
  end
end

Prawn::Article.generate("test.pdf") do
  h1 "Criteria for Disciplined Inheritance"
 
  para %{
    This is an example of building a Prawn-based article
    generator through the use of a behavioral subtype as
    an extension. It's about as wonderful and self-referential
    as you might expect.
  }

  h2 "Benefits of behavioral subtyping"

  para %{
    The benefits of behavioral subtyping cannot be directly
    known without experiencing them for yourself.
  }

  para %{
    But if you REALLY get stuck, try asking Barbara Liskov.
  }
end


=begin
module Prawn
  class Article
    def self.generate(*args, &block)
      Prawn::Document.generate(*args) do |pdf|
        new(pdf).instance_eval(&block)
      end
    end

    def initialize(document)
      self.document = document      
      document.extend(Prawn::Measurements)

      # set defaults so that @paragraph_font and @header_font are never nil.
      paragraph_font "Times-Roman"
      header_font    "Times-Roman"
    end

    def h1(contents)
      font(header_font) do
        text(contents, :size => 24)
        move_down in2pt(0.3)
      end
    end

    def h2(contents)
      font(header_font) do
        move_down in2pt(0.1)
        text(contents, :size => 16)
        move_down in2pt(0.2)
      end
    end

    def para(contents)
      font(paragraph_font) do
        text(contents.gsub(/\s+/, " "))
        move_down in2pt(0.1)
      end
    end

    def paragraph_font(font=nil)
      return @paragraph_font = font if font

      @paragraph_font
    end

    def header_font(font=nil)
      return @header_font = font if font

      @header_font
    end

    def method_missing(id, *args, &block)
      document.send(id, *args, &block)
    end

    private

    attr_accessor :document
  end
end

Prawn::Article.generate("test.pdf") do
  header_font    "Courier"
  paragraph_font "Helvetica"

  h1 "Criteria for Disciplined Inheritance"
 
  para %{
    This is an example of building a Prawn-based article
    generator through the use of a behavioral subtype as
    an extension. It's about as wonderful and self-referential
    as you might expect.
  }

  h2 "Benefits of behavioral subtyping"

  para %{
    The benefits of behavioral subtyping cannot be directly
    known without experiencing them for yourself.
  }

  para %{
    But if you REALLY get stuck, try asking Barbara Liskov.
  }
end
=end
