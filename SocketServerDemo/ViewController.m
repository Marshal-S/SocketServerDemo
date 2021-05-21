//
//  ViewController.m
//  SocketServerDemo
//
//  Created by Marshal on 2021/5/20.
//  测试案例针对ipv4,对于ipv6的支持可以搜索，或者参考GCDAsyncSocket

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface ViewController ()

@property (nonatomic, assign) int serverId;
@property (nonatomic, assign) int currentClientId;

@property (weak, nonatomic) IBOutlet UITextField *tfMessage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initServerSocket];
}

- (void)initServerSocket {
    //创建socket
    self.serverId = socket(AF_INET, SOCK_STREAM, 0);
    if (self.serverId == -1) {
        NSLog(@"创建socket失败");
        return;
    }
    //设置ip相关信息
    struct sockaddr_in socketAddr;
    socketAddr.sin_family   = AF_INET;
    //htons : 将一个无符号短整型的主机数值转换为网络字节顺序，不同cpu 是不同的顺序 (big-endian大尾顺序 , little-endian小尾顺序)
    socketAddr.sin_port = htons(8040);//设置端口号
    //inet_addr是一个计算机函数，功能是将一个点分十进制的IPv4地址转换成一个长整数型数
    socketAddr.sin_addr.s_addr =  inet_addr("172.26.105.76"); //设置ip
    //将前8个字节设置为0
    bzero(&(socketAddr.sin_zero), 8);
    
    //服务端绑定socket
    int bindResult = bind(self.serverId, (const struct sockaddr *)&socketAddr, sizeof(socketAddr));
    if (bindResult == -1) {
        NSLog(@"绑定socket失败");
        return;
    }
    
    //服务端开启监听，最大连接数量设置为5
    int listenResult = listen(self.serverId, 5);
    if (listenResult == -1) {
        NSLog(@"监听失败");
        return;
    }
    
    NSLog(@"开启监听了");
    //开始接收客户端的连接
    for (int i = 0; i < 5; i++) {
        [self acceptClientConnect];
    }
}

//监听客户端的连接
- (void)acceptClientConnect {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        struct sockaddr_in client_address;
        socklen_t address_len;
        // accept函数
        int clientSocketId = accept(self.serverId, (struct sockaddr *)&client_address, &address_len);
        self.currentClientId = clientSocketId;
        
        if (clientSocketId == -1) {
            NSLog(@"接受客户端错误: %u", address_len);
        }else{
            NSLog(@"接受客户端成功");
            [self receiveMessage:clientSocketId];
        }

    });
}

//连接成功后开始接收信息
- (void)receiveMessage:(int)clientSocketId {
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        char buffer[1024];
        ssize_t recvLen = recv(clientSocketId, buffer, sizeof(buffer), 0);
        if (recvLen > 0) {
            // 接收到的数据转换
            NSData *recvData  = [NSData dataWithBytes:buffer length:recvLen];
            NSString *recvStr = [[NSString alloc] initWithData:recvData encoding:NSUTF8StringEncoding];
            NSLog(@"接收到消息：%@",recvStr);
        }else if (recvLen == -1){
            NSLog(@"读取消息失败");
        }else if (recvLen == 0){
            NSLog(@"客户端走了");
            close(clientSocketId); //注意服务器断开socket根据id断开，这个是断开与某个对应客户端的连接
        }
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
}

- (IBAction)onSendMessage:(id)sender {
    const char *msg = self.tfMessage.text.UTF8String;
    ssize_t sendLen = send(self.currentClientId, msg, strlen(msg), 0);
    _tfMessage.text = @"";
    NSLog(@"发送成功了%ld字节", sendLen);
}

@end
