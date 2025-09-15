import { access } from '@kit.ConnectivityKit'
import { common, wantAgent } from '@kit.AbilityKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { batteryInfo, BusinessError } from '@kit.BasicServicesKit'
import { notificationManager } from '@kit.NotificationKit'
import ConstantUI from '../util/ConstantUI'


@Component
struct Index {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  @State serviceStarted: boolean = false
  @State btStateText: string = 'Bluetooth Status: UNKNOWN'
  @State isBackgroundRunning: boolean = false
  @Consume('NavPathStack') pageStack: NavPathStack
  private unsubscribeBT?: () => void

  aboutToAppear(): void {
    const cb = (err: BusinessError): void => {
      if (err) {
        console.error('[ANS] requestEnableNotification failed:', err.code, err.message)
      } else {
        console.info('[ANS] requestEnableNotification success')
      }
    }
    notificationManager.requestEnableNotification(this.context, cb)
  }

  aboutToDisappear(): void {
    this.stopBluetoothListener()
    this.stopBackground()
  }

  private async ensureNotificationSlot(): Promise<void> {
    try {
      await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION)
    } catch (e) {
      console.warn('[NOTIF] addSlot warn:', JSON.stringify(e))
    }
  }

  private async notifyBluetoothRequired(): Promise<void> {
    await this.ensureNotificationSlot()
    const req: notificationManager.NotificationRequest = {
      id: 1001,
      notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: 'Connectivity Service',
          text: 'You need to turn Bluetooth ON for phone connection.'
        }
      }
    }
    try {
      await notificationManager.publish(req)
    } catch (e) {
      console.error('[NOTIF] publish error:', JSON.stringify(e))
    }
  }

  private startBluetoothListener(): void {
    if (this.serviceStarted) return
    this.serviceStarted = true

    try {
      const current = access.getState()
      const isOn = (current === access.BluetoothState.STATE_ON || current === access.BluetoothState.STATE_BLE_ON)
      this.btStateText = isOn ? 'Bluetooth Status: ON' : 'Bluetooth Status: OFF'
      if (!isOn) this.notifyBluetoothRequired()
    } catch (e) {
      console.error('[BT] getState error:', (e as Error)?.message)
      this.btStateText = 'Bluetooth Status: UNKNOWN'
    }


    const handler = (state: access.BluetoothState) => {
      const isOn = (state === access.BluetoothState.STATE_ON || state === access.BluetoothState.STATE_BLE_ON)
      this.btStateText = isOn ? 'Bluetooth Status: ON' : 'Bluetooth Status: OFF'
      if (!isOn) this.notifyBluetoothRequired()
    }
    access.on('stateChange', handler)
    this.unsubscribeBT = () => {
      try { access.off('stateChange', handler) } catch {}
    }
  }

  private stopBluetoothListener(): void {
    if (this.unsubscribeBT) {
      this.unsubscribeBT()
      this.unsubscribeBT = undefined
    }
    this.serviceStarted = false
  }

  private async startBackground(): Promise<void> {
    const info: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: this.context.abilityInfo.bundleName,
        abilityName: this.context.abilityInfo.name
      }],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    }
    try {
      const agent = await wantAgent.getWantAgent(info)
      await backgroundTaskManager.startBackgroundRunning(
        this.context,
        backgroundTaskManager.BackgroundMode.DATA_TRANSFER, // basit arka plan modu
        agent
      )
      this.isBackgroundRunning = true
      console.info('Background task started')
    } catch (err) {
      console.error('startBackgroundRunning failed:', JSON.stringify(err))
    }
  }

  private async stopBackground(): Promise<void> {
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      console.info('Background task stopped')
    } catch (err) {
      console.error('stopBackgroundRunning failed:', JSON.stringify(err))
    } finally {
      this.isBackgroundRunning = false
    }
  }

  private async startService(): Promise<void> {
    await this.startBackground()
    this.startBluetoothListener()
  }

  private async stopService(): Promise<void> {
    this.stopBluetoothListener()
    await this.stopBackground()
  }


  build() {
    NavDestination(){
      Column({ space: ConstantUI.COLUMN_SPACE }) {
        Text('Connectivity Service')
          .fontSize(ConstantUI.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .margin({ top: 16 })

        Button(this.serviceStarted ? 'Stop' : 'Start')
          .type(ButtonType.Capsule)
          .onClick(async () => {
            if (this.serviceStarted) {
              await this.stopService()
            } else {
              await this.startService()
            }
          })
          .width('90%')

        Text(this.btStateText)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.btStateText.endsWith('ON') ? Color.Green : Color.Red)
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })

        Text(this.isBackgroundRunning ? 'Background: ON' : 'Background: OFF')
          .fontSize(12)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
      }

      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(12)

    }
    .hideTitleBar(true)

  }
}

@Builder
export function IndexPageBuilder() {
  Index()
}

