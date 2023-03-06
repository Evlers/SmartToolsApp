//
//  ProtocolStandard.h
//  SmartTools
//
//  Created by Evler on 2022/12/29.
//

#ifndef ProtocolStandard_h
#define ProtocolStandard_h

#define FCB_RAND_BIT                        0x01        // 随机数异或控制位
#define FCB_AES_BIT                         0x02        // AES 加密控制位  0-不启用 AES(ECB)  1-启用 AES(ECB)加密
#define FCB_MASK_BIT                        0x03        // FCB 掩码
#define FCB_DEFAULT                         0x01        // 默认 FCB
#define BODY_REPLY_BIT                      0x80        // Body 应答位
#define FRAME_HEAD_LEN                      3           // frame 头长度
#define BODY_HEAD_LEN                       5           // Body 头长度

#pragma pack(push)
#pragma pack(1)     // 字节对齐

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

typedef struct {
    uint16_t    length;         // App单包最大数据长度
    uint8_t     type;           // 升级类型
} ota_upgrade_request_t;        // 升级请求

typedef struct {
    uint8_t     version[3];     // 设备当前固件版本
    uint16_t    length;         // 设备单包最大数据长度
} ota_upgrade_response_t;       // 升级请求应答

typedef struct {
    uint8_t     pid[4];         // 产品ID
    uint8_t     version[3];     // 将要升级的固件本号
    uint8_t     md5[16];        // 固件文件的MD5校验值
    uint32_t    length;         // 固件文件的总长度，字节为单位
    uint32_t    crc32;          // 固件文件的CRC32校验值
} ota_upgrade_file_info_t;      // 升级文件信息

typedef struct {
    uint32_t    store_length;   // 已储存的文件长度,用于断点续传
    uint32_t    crc32;          // 已储存文件的CRC32校验值
} ota_store_file_info_t;        // 应答已储存文件信息

typedef uint32_t ota_req_file_offset_t; // 请求文件偏移
typedef uint32_t ota_res_file_offset_t; // 应答文件偏移

typedef struct {
    uint32_t    offset;         // 数据包偏移地址
    uint16_t    length;         // 数据长度
    uint16_t    crc16;          // 数据对CRC16校验值
    uint8_t     *data;          // 数据
} ota_trans_file_data_t;        // 传输文件数据

#pragma pack(pop)

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

    // Firmware Upgrade interface
    SP_CODE_UPGRADE_REQUEST = 0x50,         // 升级请求
    SP_CODE_UPGRADE_FILE_INFO,              // 文件信息
    SP_CODE_UPGRADE_FILE_OFFSET,            // 文件偏移
    SP_CODE_UPGRADE_FILE_DATA,              // 文件数据
    SP_CODE_UPGRADE_END,                    // 升级结束
    
    // Subdevice interface
    SP_CODE_UPLOAD_TOOLS = 0x30,            // 上报工具数据
    SP_CODE_DOWNLOAD_TOOLS,                 // 下发工具数据
    SP_CODE_UPLOAD_CHARGER,                 // 上报充电器数据
    SP_CODE_DOWNLOAD_CHARGER,               // 下发充电器数据
    
    // Test interface
    

    SP_CODE_NUM,
} smart_protocol_cmd_code;

typedef enum {
    OTA_UPGRADE_TYPE_BOOTLOADER = 0,        // 电池包Bootloader固件
    OTA_UPGRADE_TYPE_APP,                   // 电池包App固件
    OTA_UPGRADE_TYPE_SUBDEV,                // 子设备固件
} ota_upgrade_type;

typedef enum {
    OTA_UPGRADE_CMD_CHECK_REBOOT = 0,
    OTA_UPGRADE_CMD_CHECK = 1,
} ota_upgrade_cmd_type;


@protocol SmartProtocolDelegate <NSObject>

@required
- (void)SmartProtocolDataSend:(NSData *)data;

@optional
- (uint8_t)SmartProtocolUploadHandler:(protocol_body_t *)body response:(protocol_body_t *)rsp_body;
- (void)SmartProtocolResponseHandler:(protocol_body_t *)body with_code:(uint8_t)code;

@end

#endif /* ProtocolStandard_h */
