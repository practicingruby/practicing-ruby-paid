## Problem

*I need to test code that writes to the filesystem.*

```ruby
require "fileutils"

class Skeletor
  include FileUtils

  def self.generate(project_dir)
    new(project_dir).generate
  end

  def initialize(project_dir)
    self.project_dir = project_dir
  end

  attr_accessor :project_dir

  def generate
    cd(project_dir) do
      mkdir "lib" 
      mkdir "bin"
      touch "README.md"
      touch "Gemfile"
    end
  end
end
```

## Solution

*Use Dir.mktmpdir (provided by the tempfile standard library)*

```ruby
require "tempfile"

describe "A code generator" do
  let(:project_dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry_secure(project_dir) }

  it "generates an application skeleton" do
    Skeletor.generate(project_dir)

    FileUtils.cd(project_dir) do
      assert Dir.exist?("lib"), "expected lib dir to exist"
      assert Dir.exist?("bin"), "expected bin dir to exist"

      assert File.exist?("README.md"), "expected README.md to exist"
      assert File.exist?("Gemfile"),   "expected Gemfile to exist"
    end
  end
end
```

## Discussion

- Rolling your own
- Block form of Dir.mktmpdir
- Mocking
- Pathname
- Tempfile
- StringIO
