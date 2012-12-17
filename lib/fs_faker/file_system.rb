require 'singleton'
require 'fs_faker/fake/directory'
require 'fs_faker/fake/file'
require 'fs_faker/fake/symlink'

module FsFaker
  class FileSystem
    include Singleton

    attr_accessor :working_directory
    attr_accessor :registred_entries
    attr_accessor :root

    def initialize
      clear!
    end

    def chdir(path, &block)
      destination = find_directory!(path)

      previous_directory = working_directory
      self.working_directory = destination

      if block
        block.call
      end
    ensure
      if block
        self.working_directory = previous_directory
      end
    end

    def getwd
      working_directory.path
    end
    alias :pwd :getwd

    def find(path)
      if path == '/'
        root
      elsif dirname(path) == '.'
        working_directory.find(path)
      else
        root.find(path)
      end
    end

    def find!(path)
      find(path) || raise(Errno::ENOENT, path)
    end

    def mkdir(path)
      find_parent!(path).add_entry Fake::Directory.new(path)
    end

    def clear!
      self.root = Fake::Directory.new('/')
    end

    def directory?(path)
      find(path).is_a?(Fake::Directory)
    end

    def touch(*paths)
      paths.each do |path|
        entry = find(path)

        unless entry
          entry = Fake::File.new(path)
          parent_dir = find_parent!(path)
          parent_dir.add_entry entry
        end

        entry.touch
      end
    end

    def chmod(mode_int, file_name)
      find!(file_name).mode = mode_int
    end

    def symlink(old_name, new_name)
      find_parent!(new_name).add_entry Fake::Symlink.new(new_name, old_name)
    end

    def symlink?(path)
      find(path).is_a?(Fake::Symlink)
    end

    def entries(path)
      find_directory!(path).entry_names
    end

    def find_directory!(path)
      entry = find!(path).last_target

      unless entry.is_a?(Fake::Directory)
        raise Errno::ENOTDIR, path
      end

      entry
    end

    def find_parent!(path)
      parent_path = dirname(path)
      find_directory!(parent_path)
    end

    def dirname(path)
      FsFaker::OriginalFile.dirname(path)
    end
    
  end
end