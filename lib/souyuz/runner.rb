# -*- encoding : utf-8 -*-
module Souyuz
  class Runner
    def run
      config = Souyuz.config

      build_app

      if Souyuz.project.ios? or Souyuz.project.osx?
        compress_and_move_dsym
        path = ipa_file

        path
      elsif Souyuz.project.android?
        path = apk_file
        if (config[:keystore_path] && config[:keystore_alias])
          UI.success "Jar it, sign it, zip it..."

          jarsign_and_zipalign
        end

        path
      end
    end

    def build_app
      command = BuildCommandGenerator.generate
      FastlaneCore::CommandExecutor.execute(command: command,
                                            print_all: true,
                                            print_command: !Souyuz.config[:silent])
    end

    #
    # android build stuff to follow..
    #

    def apk_file
      build_path = Souyuz.project.options[:output_path]
      assembly_name = Souyuz.project.options[:assembly_name]

      Souyuz.cache[:build_apk_path] = "#{build_path}/#{assembly_name}.apk"

      "#{build_path}/#{assembly_name}.apk"
    end

    def jarsign_and_zipalign
      command = JavaSignCommandGenerator.generate
      FastlaneCore::CommandExecutor.execute(command: command,
                                            print_all: false,
                                            print_command: !Souyuz.config[:silent])

      UI.success "Successfully signed apk #{Souyuz.cache[:build_apk_path]}"

      command = AndroidZipalignCommandGenerator.generate
      FastlaneCore::CommandExecutor.execute(command: command,
                                            print_all: true,
                                            print_command: !Souyuz.config[:silent])
    end

    #
    # ios build stuff to follow..
    #

    def package_path
      build_path = Souyuz.project.options[:output_path]
      assembly_name = Souyuz.project.options[:assembly_name]

      package_path = Dir.glob("#{build_path}/#{assembly_name} *").sort.last
    end

    def ipa_file
      assembly_name = Souyuz.project.options[:assembly_name]

      "#{package_path}/#{assembly_name}.ipa"
    end

    def compress_and_move_dsym
      build_path = Souyuz.project.options[:output_path]
      assembly_name = Souyuz.project.options[:assembly_name]

      Souyuz.cache[:build_dsym_path] = "#{build_path}/#{assembly_name}.app.dSYM"

      command = ZipDsymCommandGenerator.generate
      FastlaneCore::CommandExecutor.execute(command: command,
                                            print_all: true,
                                            print_command: !Souyuz.config[:silent])

      # move dsym aside ipa
      dsym_path = "#{dsym_path}.zip"
      if File.exists? dsym_path
        FileUtils.mv(dsym_path, "#{package_path}/#{File.basename dsym_path}")
      end
    end
  end
end
