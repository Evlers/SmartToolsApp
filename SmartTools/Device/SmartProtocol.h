//
//  SmartProtocol.h
//  SmartTools
//
//  Created by Evler on 2022/12/27.
//

#ifndef SmartProtocol_h
#define SmartProtocol_h
#include "ProtocolStandard.h"

#define FCB_RAND_BIT                        0x01        // 随机数异或控制位
#define FCB_AES_BIT                         0x02        // AES 加密控制位  0-不启用 AES(ECB)  1-启用 AES(ECB)加密
#define FCB_MASK_BIT                        0x03        // FCB 掩码
#define FCB_DEFAULT                         0x01        // 默认 FCB
#define BODY_REPLY_BIT                      0x80        // Body 应答位
#define FRAME_HEAD_LEN                      3           // frame 头长度
#define BODY_HEAD_LEN                       5           // Body 头长度

#define FRAME_BODY_MAX_LEN                  240         // body最大长度  必须是8字节对齐
#define BODY_DATA_MAX_LEN                   230         // data最大长度  必须比body小
#define FRAME_SPLIT_MAX                     1           // 最大拆分的帧数量
#define REPLY_TIMEOUT_VALUE                 500        // 应答超时时间
#define RESEND_TRY_NUM                      2           // 重发次数

@interface Record : NSObject

@property (nonatomic, assign) uint16_t          seq;        // 发送的包序号
@property (nonatomic, assign) uint8_t           code;       // 发送的包指令代码
@property (nonatomic, assign) uint8_t           try_cnt;    // 等待超时重发计数
@property (nonatomic, strong) dispatch_block_t  block;      // 等待应答超时执行块

@end

@interface SmartProtocol : NSObject

@property (assign) id<SmartProtocolDelegate> delegate;

- (SmartProtocol *) init;

- (void)receive_data_handle:(NSData *)data;
- (void)send_connect;
- (void)send_get_command:(uint8_t)code;
- (void)send_frame_with_fcb:(uint8_t)fcb body:(protocol_body_t *)body;
- (void)send_frame_with_fcb:(uint8_t)fcb body:(protocol_body_t *)body timeout:(NSInteger)timeout;
- (void)aes_tail_key_set:(NSData *)key_tail;

@end

#endif /* SmartProtocol_h */
