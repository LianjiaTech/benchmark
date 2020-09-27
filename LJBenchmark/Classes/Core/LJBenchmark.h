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

#import <Foundation/Foundation.h>

// 添加需要hook的类
#if DEBUG
    #if __has_include("LJAspects.h")
        #define LJBM_HOOK_CLASS(__cls) \
        [LJBenchmark addHookClass:__cls]

    #else
        #define LJBM_HOOK_CLASS(__cls) do {} while (0)
    #endif
#else
    #define LJBM_HOOK_CLASS(__cls) do {} while (0)
#endif


// 方法耗时日志记录通知
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogNotification;

OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogClsKey;  // 类
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogSelKey;  // 方法
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogStartKey;  // 开始时间戳
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogEndKey;  // 结束时间戳
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogFiltTimeKey;  // 过滤时间间隔
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogDurationKey;  // 耗时 ms单位
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogDescKey;  // 简介
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogLibNameKey;  // 业务相关lib
OBJC_EXPORT NSString * const _Nonnull kLJBenchmarkLogLibClassesKey;  // 业务相关类的

NS_ASSUME_NONNULL_BEGIN

@interface LJBenchmark : NSObject

// 设置LJBenchmark是否可用
// 默认不addHookClass时不可用
+ (void)setBenchmarkAvailable:(BOOL)available;

// 添加观察某个类的执行函数耗时
+ (void)addHookClass:(Class)_cls;
// unsafety
+ (void)addHookClassName:(NSString *)_name;

// 取消观察某个类的执行函数耗时
+ (void)cancelHookClass:(Class)_cls;

// 设置log日志的过滤最小时间间隙，默认16ms
+ (void)filtLogTimeGreaterThan:(double)millisecond;

// 设置不能被观察的方法，对所有被Hook的类有效
+ (void)addSelToBlacklist:(SEL)_sel;

// 设置不能被观察的方法，仅对该类有效
+ (void)addSelOfClassToBlacklist:(Class)_cls sel:(SEL)_sel;

// 获取所有的被Hook业务仓库信息
+ (NSMutableArray<NSDictionary<NSString *, id> *> *)getHookBusinessesInfo;

// 通过类名获取类被Hook的业务仓库信息
+ (NSDictionary<NSString *, id> *)getClsBusinessInfo:(NSString *)clsName;

@end

NS_ASSUME_NONNULL_END

