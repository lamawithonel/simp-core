require 'spec_helper_acceptance'

test_name 'pupmod-simp-beakertest'

describe 'The pupmod-simp-beakertest RPM' do
  hosts.each do |host|
    install_target = unless !host.puppet['codedir'] || host.puppet['codedir'].empty?
                       host.puppet['codedir']
                     else
                       host.puppet['confdir']
                     end

    before(:all) do
      sut_yum_repo = '/srv/local_yum'
      sut_yum_repo_conf = <<-EOM.gsub(/^[[:blank:]]+/, '')
        [local_yum]
        name=Local Repos
        baseurl=file://#{sut_yum_repo}
        enabled=1
        gpgcheck=0
        repo_gpgcheck=0
      EOM

      site_module_init = "#{install_target}/environments/simp/modules/site/init.pp"
      site_manifest = <<-EOM.gsub(/^[[:blank:]]{8}/, '')
        class site {
          notify { "Hark! A Site!": }
        }
      EOM

      rpm_dist  = File.join(fixtures_path,'dist')
      rpm_stubs = File.join(fixtures_path,'test_module_rpms')

      # Sync fixture RPMs to the hosts
      on host, "mkdir -p #{sut_yum_repo}"
      src_rpms  = []
      src_rpms += Dir.glob(File.join(rpm_dist,host[:rpm_glob]))
      src_rpms += Dir.glob(File.join(rpm_stubs,'*.rpm'))

      src_rpms.each do |rpm|
        if host[:hypervisor] == 'docker'
          %x{docker cp #{rpm} #{host[:docker_container].id}:#{sut_yum_repo}}
        else
          scp_to host, rpm, sut_yum_repo
        end
      end

      # Generate repo data for the repos
      on host, 'yum install -y createrepo yum-utils'
      on host, "cd #{sut_yum_repo} && createrepo ."
      create_remote_file host, '/etc/yum.repos.d/beaker_local.repo', sut_yum_repo_conf

      # Install the `site.pp`
      host.mkdir_p File.dirname(site_module_init)
      create_remote_file host, site_module_init, site_manifest

      # Install Git for repo testing
      on host, 'yum install -y git'
      on host, 'git config --global user.email "root@rooty.tooty.invalid"'
      on host, 'git config --global user.name "Rootlike Overlord"'
    end

    after(:all) do
      on host, 'yum remove -y pupmod-simp-beakertest simp-environment'
    end

    context 'without SIMP data-copy configuration' do
      it 'installs without error' do
        host.install_package('pupmod-simp-beakertest')
      end

      it 'installs `simp-adapter` as a dependency' do
        host.check_for_package('simp-adapter')
      end

      it 'installs its files to the share directory' do
        on host, 'test -d /usr/share/simp/modules/beakertest'
      end

      it 'does NOT copy its files to the $codedir' do
        on host, "test ! -d #{install_target}/environments/simp/modules/beakertest"
      end

      it 'uninstalls without error' do
        host.uninstall_package('pupmod-simp-beakertest')
      end

      it 'removes itself from `/usr/share/simp/modules` during uninstallation' do
        on host, 'test ! -d /usr/share/simp/modules/beakertest'
      end
    end

    context 'when SIMP data-copy configuration is in place' do
      before(:context) do
        # Configure SIMP environment-copy
        config_yaml = <<-EOM.gsub(/^[[:blank:]]+/, '')
          ---
          copy_rpm_data : true
        EOM
        create_remote_file host, '/etc/simp/adapter_config.yaml', config_yaml
      end

      context 'and the Puppe $codedir is unmanaged' do
        it 'installs without error' do
          host.install_package('pupmod-simp-beakertest')
        end

        it 'installs `simp-adapter` as a dependency' do
          host.check_for_package('simp-adapter')
        end

        it 'installs its files to the share directory' do
          on host, 'test -d /usr/share/simp/modules/beakertest'
        end

        it 'copies its files into the Puppet $codedir' do
          on host, "diff -aqr /usr/share/simp/modules/beakertest #{install_target}/environments/simp/modules/beakertest"
        end

        it 'uninstalls without error' do
          host.uninstall_package('pupmod-simp-beakertest')
        end

        it 'removes itself from `/usr/share/simp/modules` during uninstallation' do
          on host, 'test ! -d /usr/share/simp/modules/beakertest'
        end

        it 'removes itself from the Puppet $codedir during uninstallation' do
          on host, "test ! -d #{install_target}/environments/simp/modules/beakertest"
        end
      end

      context 'and the Puppet $codedir is managed with Git' do
        before(:context) do
          # Stub a Git-managed control repo
          on host, "mkdir -p #{install_target}/environments/simp/{modules,manifests,data}"
          create_remote_file(host, "#{install_target}/environments/simp/git_controlled_file", '# IMA TEST')
          on host, "cd #{install_target}/environments/simp && git init . && git add git_controlled_file && git commit -a -m woo"

          # Stuba pre-existing, Git-managed beakertest module
          # TODO: This should be moved to its own context. In this context it shouldn't really matter given the control repo.
          host.mkdir_p("#{install_target}/environments/simp/modules/beakertest")
          create_remote_file(host, "#{install_target}/environments/simp/modules/beakertest/git_controlled_file", '# IMA TEST')
          on host, "cd #{install_target}/environments/simp/modules/beakertest && git init . && git add . && git commit -a -m woo"
        end

        it 'installs without error' do
          host.install_package('pupmod-simp-beakertest')
        end

        it 'installs `simp-adapter` as a dependency' do
          host.check_for_package('simp-adapter')
        end

        it 'installs its files to the share directory' do
          on host, 'test -d /usr/share/simp/modules/beakertest'
        end

        it 'does NOT copy its files into the Puppet $codedir' do
          on host, "diff -aqr /usr/share/simp/modules/beakertest #{install_target}/environments/simp/modules/beakertest",
            acceptable_exit_codes: [1]
        end

        it 'uninstalls without error' do
          host.uninstall_package('pupmod-simp-beakertest')
        end

        it 'removes itself from `/usr/share/simp/modules` during uninstallation' do
          on host, 'test ! -d /usr/share/simp/modules/beakertest'
        end

        it 'does NOT remove files from the Puppet $codedir during uninstallation' do
          on host, "test -d #{install_target}/environments/simp/modules/beakertest"
        end
      end
    end
  end
end
