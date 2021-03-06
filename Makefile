.PHONY: clean

MASTERS ?= 1
NODES ?= 2

etcd-users := calico calico-cni calico-k8s-policy

all: calico-certs
	sed -i -e "s/^num_instances=.*$$/num_instances=$$(($(NODES)+$(MASTERS)))/" Vagrantfile
	MASTERS=$(MASTERS) NODES=$(NODES) K8S_CACHED=true ./vagrant_up.sh

tls-setup/certs:
	rm -rf tmp
	cd tls-setup; make
	# Update calico manifest

	#mkdir -p tmp
	#cat tls-setup/certs/calico.pem | base64 | sed -e 's/^/    /' tmp/calico.pem
	#cat tls-setup/certs/calico-key.pem | base64 | sed -e 's/^/    /' tmp/calico-key.pem
	#cat tls-setup/certs/ca.pem | base64 | sed -e 's/^/    /' tmp/ca.pem
	#cp calico.yaml.template k8s/calico.yaml
	#sed -i -e '/calico-etcd-rbac-ca/r./tmp/ca.pem' k8s/calico.yaml
	#sed -i -e '/calico-etcd-rbac-key/r./tmp/calico-key.pem' k8s/calico.yaml
	#sed -i -e '/calico-etcd-rbac-cert/r./tmp/calico.pem' k8s/calico.yaml
	#sed -i -e '/calico-cni-etcd-rbac-key/r./tmp/calico-cni-key.pem' k8s/calico.yaml
	#sed -i -e '/calico-cni-etcd-rbac-cert/r./tmp/calico-cni.pem' k8s/calico.yaml
	# Remove all the markers that were used above

.PHONY: calico-certs
calico-certs: tls-setup/certs k8s/calico.yaml tmp $(etcd-users)
	cat tls-setup/certs/ca.pem | base64 -w 0 > tmp/ca.pem
	ca="$$(cat ./tmp/ca.pem)"; sed -i -e "s/calico-etcd-rbac-ca/$$ca/" k8s/calico.yaml
	#sed -i '/^ *calico-etcd-rbac-.*$$/d' k8s/calico.yaml

.PHONY: $(etcd-users)
$(etcd-users): k8s/calico.yaml tmp
	cat tls-setup/certs/$@.pem | base64 -w 0 > tmp/$@.pem
	cat tls-setup/certs/$@-key.pem | base64 -w 0 > tmp/$@-key.pem
	cert="$$(cat ./tmp/$@.pem)"; sed -i -e "s/$@-etcd-rbac-cert/$$cert/" k8s/calico.yaml
	key="$$(cat ./tmp/$@-key.pem)"; sed -i -e "s/$@-etcd-rbac-key/$$key/" k8s/calico.yaml
	#cat tls-setup/certs/$@.pem | base64 | sed -e 's/^/    /' > tmp/$@.pem
	#cat tls-setup/certs/$@-key.pem | base64 | sed -e 's/^/    /' > tmp/$@-key.pem

tmp:
	mkdir -p tmp

k8s/calico.yaml:
	cp calico.yaml.template k8s/calico.yaml

clean:
	cd tls-setup; make clean
	rm -f k8s/calico.yaml
	rm -rf tmp
