# SPDX-Identifier-License: Apache-2.0
# Copyright 2024-2025 MOSSDeF, Stan Grishin (stangri@melmac.ca).

include $(TOPDIR)/rules.mk

PKG_NAME:=netclient
PKG_VERSION:=0.30.0
PKG_RELEASE:=4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/gravitl/netclient/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=e86c25bca0dda02eb5207a64d7251017faeb9c00a45c4300237956aa5a6a7815

PKG_MAINTAINER:=Stan Grishin <stangri@melmac.ca>
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE.txt

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/gravitl/netclient
GO_PKG_BUILD_PKG:=github.com/gravitl/netclient
GO_PKG_LDFLAGS_X:=main.version=$(PKG_VERSION)-r$(PKG_RELEASE)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/netclient
  SECTION:=net
  CATEGORY:=Network
  URL:=https://github.com/stangri/netclient/
  TITLE:=netclient
  DEPENDS:=$(GO_ARCH_DEPENDS) +wireguard-tools
	DEPENDS+=+!BUSYBOX_DEFAULT_AWK:gawk
	DEPENDS+=+!BUSYBOX_DEFAULT_GREP:grep
	DEPENDS+=+!BUSYBOX_DEFAULT_SED:sed
endef

define Package/netclient/description
  This is the client for Netmaker networks. Netmaker automates fast, secure, and
  distributed virtual networks with Wireguard. To learn more about Netmaker, see:
  https://github.com/gravitl/netmaker
  This package contains only netclient binary, init script and netifd script.
endef

define Package/netclient/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/netclient $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/netclient.proto $(1)/lib/netifd/proto/netclient.sh
	$(SED) "s|^\(readonly PKG_VERSION\).*|\1='$(PKG_VERSION)-r$(PKG_RELEASE)'|" $(1)/lib/netifd/proto/netclient.sh
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/netclient.uci-defaults $(1)/etc/uci-defaults/30-netclient.sh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/netclient.init $(1)/etc/init.d/netclient
	$(SED) "s|^\(readonly PKG_VERSION\).*|\1='$(PKG_VERSION)-r$(PKG_RELEASE)'|" $(1)/etc/init.d/netclient
endef

define Package/netclient/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	ifdown netmaker
	uci -q del network.netmaker || true
fi
exit 0
endef

$(eval $(call GoBinPackage,netclient))
$(eval $(call BuildPackage,netclient))
