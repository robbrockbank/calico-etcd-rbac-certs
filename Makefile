.PHONY: clean

all: certs
	vagrant up

tls-setup/certs:
	cd tls-setup; make
	# Update calico manifest
	rm -rf tmp
	mkdir -p tmp
	cp tls-setup/certs/* tmp/
	sed -i -e 's/^/    /' tmp/calico*.pem
	sed -i -e 's/^/    /' tmp/ca.pem
	sed -e '/calico-etcd-rbac-key/r./tmp/calico-key.pem' calico.yaml.template > k8s/calico.yaml
	sed -i -e '/calico-etcd-rbac-cert/r./tmp/calico.pem' k8s/calico.yaml
	sed -i -e '/calico-etcd-rbac-ca/r./tmp/ca.pem' k8s/calico.yaml
	sed -i '/^ *calico-etcd-rbac-.*$$/d' k8s/calico.yaml

clean:
	cd tls-setup; make clean