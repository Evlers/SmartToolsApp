//
//  ProtocolStandard.h
//  SmartTools
//
//  Created by Evler on 2022/12/29.
//

#ifndef ProtocolStandard_h
#define ProtocolStandard_h

typedef struct {
    uint8_t         fcb;        // 帧控制字节
    uint16_t        len;        // 帧数据的长度
    uint8_t         *body;      // 帧数据
} protocol_frame_t;

typedef struct {
    uint16_t        seq;        // 序列号
    uint8_t         code;       // 命令或状态码    最高位为0代表命令  最高位为1代表状态, 0 ~ 6Bit 为错误代码
    uint16_t        len;        // 包数据的长度
    uint8_t         *data;      // 数据
    uint8_t         bcc;        // 校验结果  整个body结构按字节异或结果
} protocol_body_t;

typedef enum {
    // Basic interface
    SP_CODE_CONNECT = 1,                    // 建立连接
    SP_CODE_TIMESTAMP,                      // 设置时间戳
    SP_CODE_MANU_DATE,                      // 生产日期

    // Smart battery package interface
    SP_CODE_DEV_UUID = 0x10,                // 读取设备UUID
    SP_CODE_CHIP_ID,                        // 读取芯片ID
    SP_CODE_FIRMWARE_VER,                   // 读取固件版本
    SP_CODE_HARDWARE_VER,                   // 读取硬件版本
    SP_CODE_BAT_TEMP,                       // 读取电池包温度
    SP_CODE_PROTECT_VOLT,                   // 设置/读取电池包保护电压
    SP_CODE_MAX_DISCHARGE_CUR,              // 设置/读取电池包最大放电电流
    SP_CODE_FUNCTION_SW,                    // 设置/读取功能开关状态
    SP_CODE_WORK_MODE,                      // 设置/读取电池包工作模式
    SP_CODE_CHARGE_TIMES,                   // 读取电池包充电次数
    SP_CODE_DISCHARGE_TIMES,                // 读取电池包放电次数
    SP_CODE_WORK_TIME,                      // 读取电池包累计工作时间
    SP_CODE_CURRENT_CUR,                    // 上报/读取电池包当前电流
    SP_CODE_CURRENT_PER,                    // 上报/读取电池包当前电量
    SP_CODE_UPLOAD_EVENT,                   // 上报电池包事件
    SP_CODE_READ_BAT_VOL,                   // 上报/读取电池电压
    SP_CODE_READ_SHORT_NUM,                 // 上报/读取短路次数
    SP_CODE_READ_OVERCUR_NUM,               // 上报/读取过流次数
    SP_CODE_BATTERY_STATUS,                 // 上报/读取电池包状态

    // Subdevice interface
    SP_CODE_UPLOAD_TOOLS = 0x30,            // 上报工具数据
    SP_CODE_DOWNLOAD_TOOLS,                 // 下发工具数据
    SP_CODE_UPLOAD_CHARGER,                 // 上报充电器数据
    SP_CODE_DOWNLOAD_CHARGER,               // 下发充电器数据

    // Firmware Upgrade interface
    SP_CODE_UPGRADE_REQUEST = 0x50,         // 升级请求
    SP_CODE_UPGRADE_FILE_INFO,              // 文件信息
    SP_CODE_UPGRADE_FILE_OFFSET,            // 文件偏移
    SP_CODE_UPGRADE_FILE_DATA,              // 文件数据
    SP_CODE_UPGRADE_END,                    // 升级结束

    SP_CODE_NUM,
} smart_protocol_cmd_code;

@protocol SmartProtocolDelegate <NSObject>

@required
- (void)SmartProtocolDataSend:(NSData *)data;

@optional
- (uint8_t)SmartProtocolUploadHandler:(protocol_body_t *)body response:(protocol_body_t *)rsp_body;
- (void)SmartProtocolResponseHandler:(protocol_body_t *)body with_code:(uint8_t)code;

@end

#endif /* ProtocolStandard_h */
