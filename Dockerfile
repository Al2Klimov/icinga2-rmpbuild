FROM centos:7.5.1804 as git
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN yum install -y git ;\
	yum clean all ;\
	rm -rf /var/cache/yum

RUN cd / ;\
	git clone https://github.com/Icinga/rpm-icinga2.git ;\
	cd rpm-icinga2 ;\
	git checkout 670895bc69558d83475b3187178a119b9c1520c9 ;\
	rm -rf .git

FROM centos:7.5.1804
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm ;\
	yum clean all ;\
	rm -rf /var/cache/yum

RUN yum install -y \
	bison boost-devel ccache checkpolicy cmake flex gcc-c++ git libedit-devel libstdc++-devel logrotate make mysql-devel ncurses-devel openssl-devel postgresql-devel rpm-build selinux-policy-devel systemd-devel ;\
	yum clean all ;\
	rm -rf /var/cache/yum

COPY --from=git /rpm-icinga2 /rpm-icinga2

CMD cd /icinga2 ;\
	perl -pi -e 'if (/^Release:/) { $now = `date '+%Y.%m.%d.%H.%M'`; $gitCommit = `git log -1 --format=%h`; chomp $now; chomp $gitCommit; s/(%\{revision\})/sprintf("%s.%s.%s", $1, $now, $gitCommit)/e }' /rpm-icinga2/icinga2.spec ;\
	mkdir -p /root/rpmbuild/SOURCES/ ;\
	git archive --prefix=icinga2-2.10.2/ HEAD |gzip >/root/rpmbuild/SOURCES/v2.10.2.tar.gz ;\
	ln -vs /rpm-icinga2/icinga2.spec . ;\
	PATH="/usr/lib64/ccache:$PATH" CCACHE_DIR=/icinga2/.ccache-centos75 rpmbuild -ba icinga2.spec ;\
	rm icinga2.spec ;\
	mv -v /root/rpmbuild/SRPMS/*.rpm /root/rpmbuild/RPMS/*/*.rpm /icinga2
