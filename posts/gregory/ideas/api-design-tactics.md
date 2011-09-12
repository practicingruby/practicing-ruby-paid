######################
#Transactional blocks#
######################

## Canonical example

  File.open("timestamp.txt", "w") do |f|
    f << timestamp
  end

  vs.

  begin
    f = File.new("timestamp.txt", "w")
    f << timestamp
  ensure
    f.close
  end


  class File
    def open(*args)
      f = new(*args)
      yield(f)
    ensure
      f.close
    end
  end

## Another example

drawing_options = {
  :basename => "new_foo",
  :formats => [:png, :pdf]
}

Vectorize.draw(drawing_options) do |v|
  v.circle center: Vectorize.point(100,100), radius: 80
  v.stroke
end

# simplified implementation

module Vectorize
  def self.draw(options)
    surface = make_surface(options)

    drawing = Drawing.new(surface)
    begin
      yield drawing
    ensure
      surface.destroy
    end
  end
end


