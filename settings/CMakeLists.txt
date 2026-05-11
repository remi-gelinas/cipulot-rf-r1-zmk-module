# Custom ZMS settings backend with mount-failure auto-recovery.
# See settings_zms_force.c for the rationale + cleanup TODO.

zephyr_sources_ifdef(CONFIG_SETTINGS_CUSTOM settings_zms_force.c)

if(CONFIG_SETTINGS_CUSTOM)
  zephyr_include_directories(${ZEPHYR_BASE}/subsys/settings/include)
  zephyr_include_directories(${ZEPHYR_BASE}/subsys/settings/src)
endif()
