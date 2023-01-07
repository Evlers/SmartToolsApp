//
//  SmartProtocol.m
//  SmartTools
//
//  Created by Evler on 2022/12/27.
//
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import "SmartProtocol.h"

#define IsFcb(fcb, bit)                     ((fcb & bit) ? 1:0)
#define SetFcb(fcb, bit)                    fcb |= bit

@implementation Record

@end

@interface SmartProtocol ()

@property (nonatomic, strong) NSData *rand_a;
@property (nonatomic, strong) NSData *rand_key;
@property (nonatomic, strong) NSData *aes_key;
@property (nonatomic, assign) uint16_t pack_seq;

@property (nonatomic, strong) NSMutableArray<Record *> *queue;

@end

@implementation SmartProtocol

- (SmartProtocol *)init {
    if (self == [super init]) {
        uint8_t random[8];
        [self random_bytes:random length:sizeof(random)]; // 生成随机数
        self.rand_a = [NSData dataWithBytes:random length:sizeof(random)]; // 将随机数转换成NSData
        self.queue = [NSMutableArray array]; // 创建数据队列可变数组
        self.pack_seq = 100;
    }
    return self;
}

// 接收数据处理
- (void)receive_data_handle:(NSData *)data {
    uint8_t bcc;
    protocol_frame_t frame;
    protocol_body_t body;
    
    if ([self data_to_frame:&frame data:data] == false) { // 数据转帧
        NSLog(@"Smart battery package protocol frame error, data: %@", data);
        return ;
    }
    
    if ([self decode_body:&frame] == false) { // 解密数据
        NSLog(@"Body ciphertext decode error");
        return ;
    }
    
    NSData *body_plaintext = [NSData dataWithBytes:frame.body length:frame.len];
    
    if ([self data_to_body:&body data:body_plaintext] == false) { // 数据转包
        NSLog(@"Smart battery package protocol frame body form error, data: %@", body_plaintext);
        return ;
    }
    
    if ((bcc = [self bcc_compute:(uint8_t *)body_plaintext.bytes length:BODY_HEAD_LEN + body.len]) != body.bcc) { // 校验数据
        NSLog(@"Smart battery package protocol body chech error, compute bcc = %02X, data bcc = %02X", bcc, body.bcc);
        return ;
    }
    
    if (!(body.code & BODY_REPLY_BIT)) // 上报指令
    {
        protocol_body_t response_body = {.len = 0};
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(SmartProtocolUploadHandler:response:)]) {
            response_body.code = [self.delegate SmartProtocolUploadHandler:&body response:&response_body]; // 上报数据处理
            response_body.code |= BODY_REPLY_BIT; // 应答
            response_body.seq = body.seq; // 应答上报的包序号
            [self send_frame_with_fcb:frame.fcb body:&response_body]; // 应答
        }
    }
    else // 应答数据
    {
        for (Record *record in self.queue) { // 遍历发送队列
            if (record.seq == body.seq) { // 匹配到数据包序号
                dispatch_block_cancel(record.block); // 取消超时处理
                switch (record.code)
                {
                    case SP_CODE_CONNECT: // 握手连接应答
                    {
                        uint8_t key[8];
                        [self.rand_a getBytes:key length:sizeof(key)];
                        for (int i = 0; i < body.len; i ++) {
                            key[i] ^= body.data[i];
                        }
                        self.rand_key = [NSData dataWithBytes:key length:sizeof(key)];
                        NSLog(@"The random key a: %@", self.rand_a);
                        NSData *rand_b = [NSData dataWithBytes:body.data length:body.len];
                        NSLog(@"The random key b: %@", rand_b);
                        NSLog(@"The random algorithm key: %@", self.rand_key);
                    }
                    break;
                    
                    default: break;
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(SmartProtocolResponseHandler:with_code:)]) {
                    [self.delegate SmartProtocolResponseHandler:&body with_code:record.code]; // 应答数据处理
                }
                
                [self.queue removeObject:record]; // 从队列中删除该记录
                break;
            }
        }
    }
}

// 发送连接(握手交换随机数)
- (void)send_connect {
    protocol_body_t body;
    body.code = SP_CODE_CONNECT;
    body.len = 8; // 8字节随机数
    body.data = malloc(BODY_DATA_MAX_LEN);
    [self random_bytes:body.data length:body.len]; // 生成随机数
    self.rand_a = [NSData dataWithBytes:body.data length:body.len];
    [self send_frame_with_fcb:FCB_AES_BIT body:&body]; // 发送握手连接
}

// 发送查询指令
- (void)send_get_command:(uint8_t)code {
    protocol_body_t body;
    body.code = code;
    body.len = 0;
    [self send_frame_with_fcb:FCB_DEFAULT body:&body]; // 发送查询指令
}

// 发送数据帧
- (void)send_frame_with_fcb:(uint8_t)fcb body:(protocol_body_t *)body {
    protocol_frame_t frame;
    
    if (body->len > BODY_DATA_MAX_LEN) {
        NSLog(@"This body data is too long, body code: %d", body->code);
        return ;
    }
    
    if (!(body->code & BODY_REPLY_BIT)) // 如果不是应答数据
        body->seq = self.pack_seq ++; // 分配包序号
    
    // 生成 Frame
    frame.fcb = fcb;
    frame.len = BODY_HEAD_LEN + body->len + 1/* bcc */;
    frame.body = malloc(BODY_HEAD_LEN + body->len + 1/* bcc */ + 0x10 /* AES Data align */);
    
    if (frame.len > FRAME_BODY_MAX_LEN) {
        NSLog(@"frame body is too long, body code: %d", body->code);
        free(frame.body);
        return ;
    }
    
    frame.body[0] = body->seq & 0xff;
    frame.body[1] = body->seq >> 8;
    frame.body[2] = body->code;
    frame.body[3] = body->len & 0xff;
    frame.body[4] = body->len >> 8;
    memcpy(frame.body + BODY_HEAD_LEN, body->data, body->len);
    frame.body[BODY_HEAD_LEN + body->len] = [self bcc_compute:frame.body length:BODY_HEAD_LEN + body->len];
    
    [self encode_body:&frame]; // 加密Body数据
    
    // 组合数据帧
    NSData *send_data;
    uint8_t *send_buffer = malloc(FRAME_HEAD_LEN + frame.len);
    
    send_buffer[0] = frame.fcb;
    send_buffer[1] = frame.len & 0xFF;
    send_buffer[2] = frame.len >> 8;
    memcpy(send_buffer + FRAME_HEAD_LEN, frame.body, frame.len);
    
    send_data = [NSData dataWithBytes:send_buffer length:FRAME_HEAD_LEN + frame.len]; // 转换成NSData类型
    
    if (!(body->code & BODY_REPLY_BIT)) // 如果不是应答数据
    {
        Record *record = [Record alloc]; // 分配队列记录
        record.try_cnt = 0; //  清除重发计数
        record.code = body->code; // 保存指令代码
        record.seq = body->seq;  // 保存包序号
        [self.queue addObject:record]; // 添加发送数据到队列中(等待指令数据应答)

        // 超时应答处理
        record.block = dispatch_block_create(DISPATCH_BLOCK_BARRIER , ^{ // 创建超时处理的定时任务
            if (record.try_cnt < RESEND_TRY_NUM) { // 小于可重发次数
                NSLog(@"Smart protocol try (%d) send seq %d, code %d, data:%@", record.try_cnt + 1, record.seq, record.code, send_data);
                [self.delegate SmartProtocolDataSend:send_data]; // 重新发送数据
                record.try_cnt ++;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, REPLY_TIMEOUT_VALUE * NSEC_PER_MSEC), dispatch_get_main_queue(), record.block);

            } else { // 重发次数超出未收到应答
                [self.queue removeObject:record]; // 删除该指令记录
                NSLog(@"Smart protocol frame no response, seq %d, code %d discarded", record.seq, record.code);
            }
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, REPLY_TIMEOUT_VALUE * NSEC_PER_MSEC), dispatch_get_main_queue(), record.block);
        NSLog(@"Download seq: %d, code: %d", body->seq, body->code);
    }
    
    [self.delegate SmartProtocolDataSend:send_data]; // 发送数据
    
    free(send_buffer);
    free(frame.body);
}

// 数据编码
- (bool)encode_body:(protocol_frame_t *)frame {
    if (IsFcb(frame->fcb, FCB_AES_BIT)) {
        if (frame->len & 0x000F) { // 对齐16字节
            uint8_t pkcs7 = 0x10 - (frame->len & 0x000F);
            for(uint8_t i = 0; i < pkcs7; i ++)
                frame->body[frame->len + i] = pkcs7;
            frame->len += pkcs7;
        }
        [self aes_encrypt:frame];
    }
    
    if (IsFcb(frame->fcb, FCB_RAND_BIT)) {
        [self frame_codec:frame];
    }
    
    return true;
}

// 数据解码
- (bool)decode_body:(protocol_frame_t *)frame {
    if (IsFcb(frame->fcb, FCB_RAND_BIT)) { // 随机数异或
        [self frame_codec:frame];
    }
    
    if (IsFcb(frame->fcb, FCB_AES_BIT)) { // AES算法
        if(frame->len & 0x000F) { // 检查数据长度是否对齐 16 字节
            NSLog(@"This data is not aligned to 16 bytes !");
            return false;
        }
        
        [self aes_decrypt:frame];
        NSData *plaintext = [NSData dataWithBytes:frame->body length:frame->len];
        NSLog(@"plaintext: %@", plaintext);
    }
    
    return true;
}

// 数据转帧
- (bool)data_to_frame:(protocol_frame_t *)frame data:(NSData *)data {

    frame->fcb = ((uint8_t *)data.bytes)[0];
    frame->len = ((uint8_t *)data.bytes)[1];
    frame->len |= ((uint16_t)((uint8_t *)data.bytes)[2]) << 8;
    
    if ((frame->fcb & ~FCB_MASK_BIT) != 0 || (frame->len + FRAME_HEAD_LEN) != data.length) { // 如果帧控制字节 或者 长度不正确
        NSLog(@"frame error, frame length: %ld", data.length);
        return false;
    }
    
    frame->body = (uint8_t *)(data.bytes + FRAME_HEAD_LEN);
    return true;
}

// 数据转包
- (bool)data_to_body:(protocol_body_t *)body data:(NSData *)data {

    body->seq = ((uint8_t *)data.bytes)[0];
    body->seq |= ((uint16_t)((uint8_t *)data.bytes)[1]) << 8;
    body->code = ((uint8_t *)data.bytes)[2];
    body->len = ((uint8_t *)data.bytes)[3];
    body->len |= ((uint16_t)((uint8_t *)data.bytes)[4]) << 8;
    if ((body->len + BODY_HEAD_LEN + 1) > data.length) {
        NSLog(@"body error, body length: %ld", data.length);
        return false;
    }
    
    body->data = (uint8_t *)(data.bytes + BODY_HEAD_LEN);
    body->bcc = ((uint8_t *)data.bytes)[BODY_HEAD_LEN + body->len];
    return true;
}

// AES加密
- (void)aes_encrypt:(protocol_frame_t *)frame {
    
    size_t ciphertext_len = 0;
    uint8_t key_ptr[kCCKeySizeAES128];
    
    memset(key_ptr, 0, sizeof(key_ptr));
    [self.aes_key getBytes:key_ptr length:sizeof(key_ptr)];
    
    size_t buffer_size = frame->len + kCCBlockSizeAES128;
    void *buffer = malloc(buffer_size);
    
    CCCryptorStatus status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, key_ptr, sizeof(key_ptr), nil,
            frame->body, frame->len, buffer, buffer_size, &ciphertext_len);
    
    if (status == kCCSuccess && ciphertext_len == frame->len) {
        memcpy(frame->body, buffer, ciphertext_len);
    }
    
    free(buffer);
}

// AES解密
- (void)aes_decrypt:(protocol_frame_t *)frame {
    
    size_t ciphertext_len = 0;
    uint8_t key_ptr[kCCKeySizeAES128];
    
    memset(key_ptr, 0, sizeof(key_ptr));
    [self.aes_key getBytes:key_ptr length:sizeof(key_ptr)];
    
    size_t buffer_size = frame->len + kCCBlockSizeAES128;
    void *buffer = malloc(buffer_size);
    
    CCCryptorStatus status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionECBMode, key_ptr, sizeof(key_ptr), nil,
            frame->body, frame->len, buffer, buffer_size, &ciphertext_len);
    
    if (status == kCCSuccess && ciphertext_len == frame->len) {
        memcpy(frame->body, buffer, ciphertext_len);
    }
    
    free(buffer);
}

// 异或运算编解码
- (void)frame_codec:(protocol_frame_t *)frame {
    if (self.rand_key == nil) return ;
    for(uint16_t i = 0; i < frame->len; i ++) {
        ((uint8_t *)frame->body)[i] ^= ((uint8_t *)self.rand_key.bytes)[i % 8];
    }
}

// 设置aes尾部密钥
- (void)aes_tail_key_set:(NSData *)key_tail {
    uint8_t aes_key[16];
    const uint8_t key_head[8] = { 0x62,0x75,0x21,0x39,0x16,0x54,0x31,0x15 };
    
    for (uint8_t i = 0; i < key_tail.length; i ++) {
        ((uint8_t *)key_tail.bytes)[i] ^= 0x86;
    }
    
    memcpy(aes_key + 0, key_head, 8);
    memcpy(aes_key + 8, key_tail.bytes, 8);
    
    self.aes_key = [NSData dataWithBytes:aes_key length:sizeof(aes_key)];
    NSLog(@"The AES(ECB) algorithm key: %@", self.aes_key);
}

// 计算异或校验值
- (uint8_t)bcc_compute:(uint8_t *)data length:(uint16_t) len {
    uint8_t bcc = 0;
    
    for(uint16_t i = 0; i < len; i ++) {
        bcc ^= data[i];
    }
    return bcc;
}

- (void)random_bytes:(uint8_t *)bytes length:(NSInteger)len {
    srand((unsigned)time(0));
    for (NSInteger i = 0; i < len; i ++) {
        bytes[i] = rand();
    }
}

@end
