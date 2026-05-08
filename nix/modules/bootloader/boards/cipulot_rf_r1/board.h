#ifndef BOARD_H_
#define BOARD_H_

#define LED_PORT GPIOB
#define LED_PIN GPIO_PIN_3
#define LED_STATE_ON 1

#define BOARD_FLASH_SIZE (512 * 1024)
#define BOARD_FLASH_SECTORS 8

//--------------------------------------------------------------------+
// USB — TODO: pick a VID:PID. pid.codes free range or 0x1209:0x0001
// for personal use. Strings below identify the bootloader on the host.
//--------------------------------------------------------------------+
#define USB_VID 0x1209
#define USB_PID 0x0001
#define USB_MANUFACTURER "Cipulot"
#define USB_PRODUCT "RF R1"

#define UF2_PRODUCT_NAME USB_MANUFACTURER " " USB_PRODUCT
#define UF2_BOARD_ID "Cipulot-RF-R1-rev1"
#define UF2_VOLUME_LABEL "RFR1BOOT"
#define UF2_INDEX_URL ""

#define USB_NO_VBUS_PIN 1

static inline void clock_init(void) {
  RCC_ClkInitTypeDef RCC_ClkInitStruct;
  RCC_OscInitTypeDef RCC_OscInitStruct;

  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);

  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = HSE_VALUE / 1000000;
  RCC_OscInitStruct.PLL.PLLN = 336;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
  RCC_OscInitStruct.PLL.PLLQ = 7;
  HAL_RCC_OscConfig(&RCC_OscInitStruct);

  RCC_ClkInitStruct.ClockType = (RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK |
                                 RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2);
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
  HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2);
}

#endif
