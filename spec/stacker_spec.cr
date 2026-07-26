require "./spec_helper.cr"

describe Stacker do
  describe ".unknown_args" do
    # Kemal used to receive the leftover arguments and parse them, but the bind
    # address and port are always overridden from the config file afterwards: a
    # `-p 3999` was accepted and silently ignored.
    it "should report arguments Stacker does not act on" do
      Stacker.unknown_args(["server"]).should eq([] of String)
      Stacker.unknown_args(["server", "--config", "stacker.yml"]).should eq([] of String)
      Stacker.unknown_args(["server", "-c", "stacker.yml"]).should eq([] of String)
      Stacker.unknown_args(["server", "-p", "3999"]).should eq(["-p", "3999"])
      Stacker.unknown_args(["server", "--config", "stacker.yml", "-b", "0.0.0.0"]).should eq(["-b", "0.0.0.0"])
    end

    it "should not fail on a trailing config flag" do
      Stacker.unknown_args(["server", "--config"]).should eq([] of String)
      Stacker.unknown_args(["server", "-c"]).should eq([] of String)
    end
  end

  describe ".reopen_log_file!" do
    # The backend memoized the File it wrote to, so after a logrotate the process
    # kept writing to the renamed file and the new one stayed empty.
    it "should write to a fresh file after the log file has been rotated" do
      previous_config = Stacker.config?
      previous_logger = Stacker.logger
      log_file = File.tempname("stacker-spec", ".log")

      begin
        Stacker.config = Stacker::Config.from_yaml(<<-YAML)
        ---
        doc_root: .
        entrypoint: sp
        log_file: #{log_file}
        stacks: {}
        YAML
        Stacker.logger = nil
        Stacker.setup_log

        Log.for("spec").info { "before-rotation" }
        # The backend dispatches writes asynchronously: closing it drains the queue.
        Stacker.logger.close
        File.rename(log_file, "#{log_file}.rotated")

        Stacker.reopen_log_file!
        Log.for("spec").info { "after-rotation" }
        Stacker.logger.close

        File.exists?(log_file).should be_true
        File.read(log_file).should contain("after-rotation")
        File.read("#{log_file}.rotated").should_not contain("after-rotation")
      ensure
        Stacker.config = previous_config
        Stacker.logger = previous_logger
        Log.setup(:none)
        File.delete?(log_file)
        File.delete?("#{log_file}.rotated")
      end
    end
  end

  describe ".config" do
    it "should raise a clear error when no configuration is loaded" do
      previous = Stacker.config?
      Stacker.config = nil

      begin
        expect_raises(Stacker::Error, /configuration not loaded/) { Stacker.config }
      ensure
        Stacker.config = previous
      end
    end
  end
end
