function(update_board TARGET)
  target_sources(${TARGET}
                 PUBLIC ${ST_CMSIS}/Source/Templates/gcc/startup_stm32f411xe.s)

  target_compile_definitions(
    ${TARGET} PUBLIC STM32F411xE HSE_VALUE=8000000U
                     TINYUF2_PROTECT_BOOTLOADER=0 TUF2_LOG=0 CFG_TUSB_DEBUG=0)

  target_link_options(${TARGET} PUBLIC -Wl,--gc-sections)
endfunction()
