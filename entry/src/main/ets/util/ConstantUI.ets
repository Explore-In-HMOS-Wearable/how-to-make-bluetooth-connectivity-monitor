export default class ConstantUI {
  // === Fonts ===
  static readonly FONT_SIZE_TITLE: number = 24
  static readonly FONT_SIZE_SUBTITLE: number = 16
  static readonly FONT_SIZE_MESSAGE: number = 14

  // === Buttons ===
  static readonly BUTTON_WIDTH: string = '70%'
  static readonly BUTTON_HEIGHT_PRIMARY: number = 44
  static readonly BUTTON_HEIGHT_SECONDARY: number = 40

  // === Layout ===
  static readonly COLUMN_SPACE: number = 20

  static readonly PADDING: number = 24

  // === Battery / Background ===
  static readonly BATTERY_INTERVAL: number = 15000
  static readonly NOTIFICATION_ID: number = 7001

  // === Splash ===
  static readonly SPLASH_DELAY_MS: number = 2000
  static readonly FULL_WIDTH: string = '100%'
  static readonly FULL_HEIGHT: string = '100%'

  // Page transitions (ms)
  static readonly TRANSITION_ENTER_DURATION: number = 400
  static readonly TRANSITION_EXIT_DURATION: number = 400

  // Resources
  static readonly RES_LOTTIE_REMINDER: string = 'resources/rawfile/bluetooth_splash.json'
}
