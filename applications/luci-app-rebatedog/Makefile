

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.4-20231207
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for rebatedog
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-iform +luci-lib-taskd
LUCI_EXTRA_DEPENDS:=luci-lib-iform (>=1.1)

define Package/luci-app-rebatedog/conffiles
/etc/config/rebatedog
endef

define Package/luci-app-rebatedog/postinst
#!/bin/sh
chmod 777 /usr/libexec/istorec/rebatedog.sh
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

