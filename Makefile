DESTDIR = /tmp/rf-certutil-$(USER)
BINDIR = /usr/bin

all:

install: install-dirs install-files

install-dirs:
	for dir in /etc/rf-certutil/vpn-client /var/lib/rf-certutil/keys /usr/share/rf-certutil $(BINDIR) \
	         /var/lib/rf-certutil/certs /var/lib/rf-certutil/mgmt/newcerts /var/log/rf-certutil ; \
	do \
	    install -d $(DESTDIR)/$$dir ; \
	done

install-files:
	for lib in openssl-ca.cnf openssl-req.cnf certutil.lib.sh rf-certutil.conf old-vpn-ca.crt index.txt.attr ; \
        do \
	    install -m 544 -T $$lib $(DESTDIR)/usr/share/rf-certutil/$$lib ;\
	done
	for bin in rf-certutil-gen-ca rf-certutil-gen-ldap \
	rf-certutil-gen-vpn-client rf-certutil-gen-vpn-server \
	rf-certutil-gen-subca-ldap rf-certutil-gen-subca-vpn \
	rf-certutil-gen-subca-https rf-certutil-gen-https \
	rf-certutil-gen-proxy-ca rf-certutil-gen-subca-proxy-ca ; \
	do \
	    install -m 544 -T $$bin $(DESTDIR)/$(BINDIR)/$$bin ; \
	done
	for cfg in vpn-client/default* ; \
	do \
	    install -m 544 -T $$cfg $(DESTDIR)//etc/rf-certutil/$$cfg ; \
	done
