require 'spec_helper_acceptance'

test_name 'rpm_build'

builder = only_host_with_role(hosts, 'builder')
build_dir = '/tmp/simp-adapter'
common_build_deps = [
  'augeas-devel',
  'createrepo',
  'genisoimage',
  'git',
  'gnupg2',
  'libicu-devel',
  'libxml2',
  'libxml2-devel',
  'libxslt',
  'libxslt-devel',
  'mock',
  'rpm-sign',
  'rpmdevtools',
  'gcc',
  'gcc-c++',
  'ruby-devel',
]

describe 'The RPM build' do
  context 'with a properly initialized environment' do
    before(:context) do
      # Sync relevant files files to the build host
      on builder, "mkdir -p #{build_dir}/{build,spec,src,puppet_config}"
      scp_to builder, File.join(Dir.pwd, 'Gemfile'), "#{build_dir}/"
      scp_to builder, File.join(Dir.pwd, 'Rakefile'), "#{build_dir}/"
      rsync_to builder, File.join(Dir.pwd, 'build'), "#{build_dir}/build"
      rsync_to builder, File.join(Dir.pwd, 'spec', 'fixtures'), "#{build_dir}/spec/fixtures"
      rsync_to builder, File.join(Dir.pwd, 'src'), "#{build_dir}/src"
      rsync_to builder, File.join(Dir.pwd, 'puppet_config'), "#{build_dir}/puppet_config"

      # Install build deps
      on builder, "yum install -y #{common_build_deps.join(' ')}"
      on builder, 'git config --global user.email "root@rooty.tooty.invalid"'
      on builder, 'git config --global user.name "Rootlike Overlord"'

      # Install RVM
      on builder, "gpg --import #{build_dir}/spec/fixtures/rvm_signing.gpg"
      on builder, 'cd /tmp; curl -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer'
      on builder, 'cd /tmp; curl -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer.asc'
      on builder, 'cd /tmp; gpg --verify rvm-installer.asc && bash rvm-installer stable'
      on builder, 'rvm install 2.1.10 && rvm --default use 2.1.10'
      on builder, 'gem install bundler'
    end

    after(:context) do
      # Remove RVM so it doesn't interfere with subsiquent tests
      on builder, 'rvm implode --force && rm -rf /etc/rvm'
    end

    it 'should build cleanly' do |example|
      on builder, "cd #{build_dir}; bundle install"
      on builder, "cd #{build_dir}; bundle exec rake pkg:rpm[#{builder[:mock_chroot]},true]"

      # Save the generated RPMs
      unless example.exception
        begin
          Dir.mkdir(File.join(Dir.pwd, 'spec', 'fixtures', 'dist'))
        rescue Errno::EEXIST
          nil
        end
        scp_from builder, "#{build_dir}/dist/simp-adapter-0.0.1-0.noarch.rpm",    File.join(Dir.pwd, 'spec', 'fixtures', 'dist')
        scp_from builder, "#{build_dir}/dist/simp-adapter-pe-0.0.1-0.noarch.rpm", File.join(Dir.pwd, 'spec', 'fixtures', 'dist')
      end
    end
  end
end
