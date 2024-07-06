%global gitcommit 0df7fc4

Summary: RF certutil
Name: rf-certutil
Version: 0.0
Release: 0.4.%{gitcommit}_git%{?dist}
Group: Applications/System
# COMMIT=af61c65; git archive --format=tar --prefix=rf-certutil-$COMMIT/ $COMMIT | gzip > ../rf-certutil-$COMMIT.tar.gz
Source0: rf-certutil-%{gitcommit}.tar.gz
License: GPL
BuildArch: noarch

%description
Simple set of cert utils

%prep
%setup -q -n rf-certutil-%{gitcommit}

%build

%install
rm -rf $RPM_BUILD_ROOT/
make DESTDIR=$RPM_BUILD_ROOT install

%pre
getent group rf-certutil > /dev/null || groupadd -r rf-certutil
getent passwd rf-certutil > /dev/null || useradd -r -g rf-certutil -d /var/lib/rf-certutil -s /sbin/nologin rf-certutil

%files
%attr(755,root,root) %dir /etc/rf-certutil
%attr(755,root,root) %dir /etc/rf-certutil/vpn-client
%config /etc/rf-certutil/vpn-client/default.conf
%config /etc/rf-certutil/vpn-client/default.mail.tpl
%config /etc/rf-certutil/vpn-client/default.sms.tpl
%attr(755,rf-certutil,rf-certutil) %dir /var/lib/rf-certutil
%attr(755,rf-certutil,rf-certutil) %dir /var/lib/rf-certutil/keys
%attr(755,rf-certutil,rf-certutil) %dir /var/lib/rf-certutil/certs
%attr(755,rf-certutil,rf-certutil) %dir /var/lib/rf-certutil/mgmt
%attr(755,rf-certutil,rf-certutil) %dir /var/lib/rf-certutil/mgmt/newcerts
%attr(755,rf-certutil,rf-certutil) %dir /var/log/rf-certutil
%attr(755,root,root) %dir /usr/share/rf-certutil
%attr(444,root,root) /usr/share/rf-certutil/openssl-ca.cnf
%attr(444,root,root) /usr/share/rf-certutil/openssl-req.cnf
%attr(444,root,root) /usr/share/rf-certutil/certutil.lib.sh
%attr(444,root,root) /usr/share/rf-certutil/rf-certutil.conf
%attr(444,root,root) /usr/share/rf-certutil/old-vpn-ca.crt
%attr(444,root,root) /usr/share/rf-certutil/index.txt.attr
%attr(555,root,root) /usr/bin/rf-certutil-gen-ca
%attr(555,root,root) /usr/bin/rf-certutil-gen-ldap
%attr(555,root,root) /usr/bin/rf-certutil-gen-vpn-client
%attr(555,root,root) /usr/bin/rf-certutil-gen-vpn-server
%attr(555,root,root) /usr/bin/rf-certutil-gen-subca-ldap
%attr(555,root,root) /usr/bin/rf-certutil-gen-subca-vpn
%attr(555,root,root) /usr/bin/rf-certutil-gen-subca-https
%attr(555,root,root) /usr/bin/rf-certutil-gen-https
%attr(555,root,root) /usr/bin/rf-certutil-gen-proxy-ca
%attr(555,root,root) /usr/bin/rf-certutil-gen-subca-proxy-ca

%changelog
* Sat Jul 06 2024 Rolf Fokkens <rolf@rolffokkens.nl> 0.0-0
- Initial version

