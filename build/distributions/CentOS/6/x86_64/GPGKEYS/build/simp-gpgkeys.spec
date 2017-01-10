Summary: GPGKEYS
Name: simp-gpgkeys
Version: 2.0.0
Release: 3%{?dist}
License: Public Domain
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Buildarch: noarch
Requires: facter

Prefix: %{_datadir}/simp/GPGKEYS

%description
A collection of GPG Keys Required for SIMP to function properly.

All keys copyright their respective owners.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

# Make your directories here.
mkdir -p %{buildroot}/%{_sysconfdir}/pki/rpm-gpg
mkdir -p %{buildroot}/%{prefix}

#Now install the files.
cp RPM-GPG-KEY* %{buildroot}/%{_sysconfdir}/pki/rpm-gpg
cp RPM-GPG-KEY* %{buildroot}/%{prefix}

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files
%defattr(0644,root,root,0755)
%{_sysconfdir}/pki/rpm-gpg
%{prefix}

%post
#!/bin/bash

# If we're a SIMP server, place the keys into the appropriate web directory

dir='/srv/www/yum/SIMP'
if [ ! -d $dir ]; then
  mkdir -p -m 0755 "${dir}/GPGKEYS"
fi
cp %{prefix}/RPM-GPG-KEY* "${dir}/GPGKEYS"

# Get rid of any files that are present that aren't in the new directory.
# Ensure that we don't have issues with operations in progress.
old_key_list=`mktemp --suffix=.simp_gpgkeys`
new_key_list=`mktemp --suffix=.simp_gpgkeys`

find "${dir}/GPGKEYS" -name "RPM-GPG-KEY*" -maxdepth 1 -printf "%f\n" | sort -u > $old_key_list
find "%{prefix}" -name "RPM-GPG-KEY*" -maxdepth 1 -printf "%f\n" | sort -u > $new_key_list

for file in `comm -23 $old_key_list $new_key_list`; do
  if [ -f "${dir}/GPGKEYS/${file}" ]; then
    rm -f "${dir}/GPGKEYS/${file}"
  fi
done

if [ -f $old_key_list ]; then
  rm -f $old_key_list
fi

if [ -f $new_key_list ]; then
  rm -f $new_key_list
fi

# Link system GPG keys into SIMP repo
if [ `facter operatingsystem` == 'CentOS' ]; then
  search_string='.*CentOS-[[:digit:]]'
elif [ `facter operatingsystem` == 'RedHat' ]; then
  search_string='.*redhat.*release.*'
else
  search_string=''
fi
if [ -n "$search_string" ]; then
  for file in `find /etc/pki/rpm-gpg/ -regextype posix-extended -regex ${search_string}`; do
    cp ${file} ${dir}/GPGKEYS
  done
fi

# Ensure GPG permissions
chown -R root:48 ${dir}/GPGKEYS/
find ${dir}/GPGKEYS/ -type f -exec chmod 640 {} +


%postun
#!/bin/bash

dir='/srv/www/yum/SIMP'
if [ -d "${dir}/GPGKEYS" ]; then
  find -P "${dir}/GPGKEYS/" -type f -xdev -xautofs -delete
fi

%changelog
* Tue Oct 27 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-3
- Fixed some logic bugs in the %postinstall script

* Tue Jul 28 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-2
- Now install the GPG keys to /usr/share/simp/GPGKEYS and /etc/pki/rpm-gpg
- Copy the keys into the SIMP default web dirs if they exist and be sure to
  clean up after ourselves in the future.

* Sat Jun 27 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-1
- Added the OS version to differentiate between the versions.

* Mon May 25 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.0-0
- Initial Public Release
