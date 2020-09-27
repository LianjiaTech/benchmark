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

#if __has_include("LJBenchmark.h")

#if DEBUG

#import <Foundation/Foundation.h>
#import "LJBenchmark.h"

@interface LJBMUserCustomConfiguration : NSObject

@end

@implementation LJBMUserCustomConfiguration

+ (void)userCustomConfiguration {
    // 设置时长0.01ms内的耗时都监听
    [LJBenchmark filtLogTimeGreaterThan:0.001];
    [LJBenchmark addHookClassName:@"LJTestAsynchronous"];
    [LJBenchmark addHookClassName:@"LJViewController"];
}

+ (void)load {
    [self userCustomConfiguration];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(benchmarkTaskNotification:) name:kLJBenchmarkLogNotification object:nil];
    
}

+ (void)benchmarkTaskNotification:(NSNotification *)notification {
    NSLog(@"%@", notification.object);
}

@end

#endif

#endif
