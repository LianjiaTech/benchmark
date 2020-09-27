/*
* Copyright(c) 2019 Lianjia, Inc. All Rights Reserved
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
* associated documentation files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
* and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
* so, subject to the following conditions:

* The above copyright notice and this permission notice shall be included in all copies or substantial
* portions of the Software.

* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
* OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
* ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
*/

#import "LJBenchmarkTaskManager.h"
#import "LJBenchmark.h"

@interface LJBenchmarkTaskManager ()

@property (nonatomic, strong) NSMutableArray *tasksArr;

@property (nonatomic, copy) dispatch_queue_t dataQueue;

@end

@implementation LJBenchmarkTaskManager

#pragma mark - life cycle
+(instancetype)sharedInstance {
    static LJBenchmarkTaskManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
        [_sharedManager startMonitor];
    });
    return _sharedManager;
}

-(instancetype)init{
    
    if (self = [super init]) {
        _tasksArr = [NSMutableArray array];
        _dataQueue = dispatch_queue_create("com.lianjia.benchmark.data", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - 添加通知任务
- (void)addTimeDic:(NSMutableDictionary *)task{
    [self.tasksArr addObject:task?:[NSMutableDictionary dictionary]];
}

#pragma mark - 开启&停止监听
static CFRunLoopObserverRef _defaultModeObserver;
-(void)startMonitor{
    
    if (!_defaultModeObserver){
        
        CFRunLoopObserverContext context = {
            0,
            (__bridge void *)(self),
            &CFRetain,
            &CFRelease,
            NULL
        };
        
        _defaultModeObserver = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                       kCFRunLoopBeforeWaiting,
                                                       YES,
                                                       0,
                                                       &callBack,
                                                       &context);
        CFRunLoopAddObserver(CFRunLoopGetMain(), _defaultModeObserver, kCFRunLoopCommonModes);
        CFRelease(_defaultModeObserver);
    }
}

//停止监听，预留接口
- (void)endMonitor{
    
    if (!_defaultModeObserver) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _defaultModeObserver, kCFRunLoopCommonModes);
    _defaultModeObserver = NULL;
}

static void callBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    
    safe_task_queue(^{
        
        LJBenchmarkTaskManager *manager = (__bridge LJBenchmarkTaskManager *)info;
        
        if (manager.tasksArr.count == 0) return;
        
        NSInteger count = MIN(manager.tasksArr.count, 100);
        NSMutableArray *notifiTasks = [NSMutableArray arrayWithCapacity:count];
        for (NSInteger index = 0; index < count; index ++) {
            
            NSMutableDictionary *timeDic = [manager.tasksArr firstObject];
            
            double startTime = [[timeDic objectForKey:kLJBenchmarkLogStartKey] doubleValue];
            double endTime = [[timeDic objectForKey:kLJBenchmarkLogEndKey] doubleValue];
            double ljbm_filtLogTime = [[timeDic objectForKey:kLJBenchmarkLogFiltTimeKey] doubleValue];
            double detaT = (endTime - startTime) /* * 1000*/;
            
            if (detaT >= ljbm_filtLogTime) {
                NSString *duration = [NSString stringWithFormat:@"%.5lf", detaT];
                [timeDic setObject:duration forKey:kLJBenchmarkLogDurationKey];
                NSString *descValue = [timeDic objectForKey:kLJBenchmarkLogDescKey];
                descValue = [descValue stringByAppendingFormat:@" Duration: %@ ms", duration];
                [timeDic setObject:descValue forKey:kLJBenchmarkLogDescKey];
        
                [notifiTasks addObject:timeDic];
            }
            if (manager.tasksArr.count>0) {
                [manager.tasksArr removeObjectAtIndex:0];
            }
        }
        
        if (notifiTasks.count > 0) {
            safe_main_queue(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kLJBenchmarkLogNotification object:notifiTasks];
            });
        }
        
    });
}

#pragma mark - 线程安全
void safe_main_queue (dispatch_block_t block){
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void safe_task_queue (dispatch_block_t block){
    
    if (block) {
        dispatch_async([LJBenchmarkTaskManager sharedInstance].dataQueue, block);
    }
}

@end
