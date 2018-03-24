
BUILDDIR ?= $(shell pwd)/build
UID ?= $(shell id -u)
GID ?= $(shell id -g)

KERNEL_DOCKERFILE ?= Dockerfile.kernel
RAMROOT_DOCKERFILE ?= Dockerfile.ramroot

KERNEL_IMAGE := ramroot-kernel
SYSTEM_IMAGE := ramroot

MKDIR_P := mkdir -p

.PHONY: package package-kernel kernel-image package-system system-image run-kernel run-system


package: package-kernel package-system

kernel-image:
	docker build -f $(KERNEL_DOCKERFILE) -t $(KERNEL_IMAGE) .

system-image:
	docker build -f $(RAMROOT_DOCKERFILE) -t $(SYSTEM_IMAGE) .


.ONESHELL:
package-kernel: kernel-image
	$(MKDIR_P) $(BUILDDIR)
	docker run --rm -v $(BUILDDIR):/host $(KERNEL_IMAGE) bash -c "cp -v /boot/initrd.img-* /boot/vmlinuz-* /host; chown $(UID):$(GID) /host/{vmlinuz,initrd.img}-*"
	mv $(BUILDDIR)/vmlinuz-* $(BUILDDIR)/vmlinuz
	mv $(BUILDDIR)/initrd.img-* $(BUILDDIR)/initrd
	chmod 644 $(BUILDDIR)/*

.ONESHELL:
package-system: system-image
	$(MKDIR_P) $(BUILDDIR)
	tools/docker-to-ramroot $(SYSTEM_IMAGE) $(BUILDDIR)/ramroot.tar.xz

run-kernel: kernel-image
	@docker run --rm -it $(KERNEL_IMAGE) bash -li

run-system: system-image
	@docker run --rm -it $(SYSTEM_IMAGE) bash -li
