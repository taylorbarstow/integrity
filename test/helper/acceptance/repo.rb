# coding: utf-8

module TestHelper
  class GitRepo
    attr_reader :path, :branch

    alias_method :uri, :path

    def initialize(name = "test_repo", branch = "master")
      @path   = Integrity.config.directory.join(name)
      @branch = branch
    end

    def create
      FileUtils.mkdir(@path)

      Dir.chdir(@path) {
        `git init`
        `git config user.name 'John Doe'`
        `git config user.email 'johndoe@example.org'`
      }

      add_commit("First commit") {
        `echo 'just a test repo' >> README`
        `git add README`
      }
    end

    def add_successful_commit
      add_commit("This commit will work") {
        `echo '#{script(0)}' > test`
        `chmod +x test`
        `git add test`
      }
    end

    def add_failing_commit
      add_commit("This commit will fail") {
        `echo '#{script(1)}' > test`
        `chmod +x test`
        `git add test`
      }
    end
    
    def add_commit_with_very_long_commit_message_lines
      # 2000 chars
      subject = '123456789 ' * 200
      message = "#{subject} end-subject\n\nAnd again in body:\n\n#{subject} end-body"
      add_commit(message) {
        `echo '#{script(0)}' > test`
        `chmod +x test`
        `git add test`
      }
    end
    
    def add_commit_with_utf8_subject_and_body
      subject = 'Коммит'
      message = "#{subject} end-subject\n\nAnd again in body:\n\n#{subject} end-body"
      add_commit(message) {
        `echo '#{script(0)}' > test`
        `chmod +x test`
        `git add test`
      }
    end

    def add_commit_with_utf8_command_output
      add_commit("This commit will work") {
        `echo '#{utf8_script(0)}' > test`
        `chmod +x test`
        `git add test`
      }
    end

    def head
      Dir.chdir(@path) { `git log --pretty=format:%H | head -1`.chomp }
    end

    def short_head
      head[0..6]
    end

    def commits
      Dir.chdir(@path) {
        `git log --pretty=format:%H`.each_line.collect{|l| l.split("\n").first}.
        inject([]) { |acc, sha1|
          # Note: psych will return unquoted timestamp as a Time object,
          # syck will return it as a string
          # Note: use single quotes because of how we invoke git below
          fmt  = "---%nmessage: >-%n  %s%ntimestamp: '%ci'%n" \
            "id: %H%nauthor: %n name: %an%n email: %ae%n"
          acc << YAML.load(`git show -s --pretty=format:"#{fmt}" #{sha1}`)
        }.reverse
      }
    end

    def add_commit(message)
      Dir.chdir(@path) {
        yield
        `git commit -m "#{@branch}: #{message}" \
           --author="John Doe <jdoe@gmail.com>"`
      }
    end

    def checkout(branch)
      @branch = branch
      Dir.chdir(@path) { `git checkout -b #{branch} > /dev/null 2>&1` }
    end

    def script(status)
      <<SH
  #!/bin/sh
  echo "Running tests..."
  exit #{status}
SH
    end

    def utf8_script(status)
      <<SH
  #!/bin/sh
  echo "Тесты выполняются..."
  exit #{status}
SH
    end
  end
end
