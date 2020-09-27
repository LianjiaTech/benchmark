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

#import "LJBenchmark.h"
#import <dlfcn.h>
#import <mach-o/ldsyms.h>
#import <mach-o/getsect.h>
#import <mach-o/dyld.h>

#import "LJClassInfo.h"
#import "LJAspects.h"

#import <sys/time.h>
#import <pthread.h>

#import "LJBenchmarkTaskManager.h"

#define __ljbm_default_blacklist [NSMutableSet setWithArray:@[@".cxx_destruct", @"dealloc", @"init"]]

NSString * const _Nonnull kLJBenchmarkLogNotification = @"kLJBenchmarkLogNotification";

NSString * const _Nonnull kLJBenchmarkLogClsKey = @"kLJBenchmarkLogClsKey";
NSString * const _Nonnull kLJBenchmarkLogSelKey = @"kLJBenchmarkLogSelKey";
NSString * const _Nonnull kLJBenchmarkLogStartKey = @"kLJBenchmarkLogStartKey";
NSString * const _Nonnull kLJBenchmarkLogEndKey = @"kLJBenchmarkLogEndKey";
NSString * const _Nonnull kLJBenchmarkLogFiltTimeKey = @"kLJBenchmarkLogFiltTimeKey";
NSString * const _Nonnull kLJBenchmarkLogDurationKey = @"kLJBenchmarkLogDurationKey";
NSString * const _Nonnull kLJBenchmarkLogDescKey = @"kLJBenchmarkLogDescKey";
NSString * const _Nonnull kLJBenchmarkLogLibNameKey = @"kLJBenchmarkLogLibNameKey";
NSString * const _Nonnull kLJBenchmarkLogLibClassesKey = @"kLJBenchmarkLogLibClassesKey";



static BOOL ljbm_benchmarkAvailable = NO;
static NSMutableSet<NSString *> *ljbm_blacklist = nil;
static NSMutableSet *ljbm_whiteList = nil;
static double ljbm_filtLogTime = 16.0;
static NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *ljbm_Cls_Sel_dic = nil;
static NSMutableArray<NSDictionary<NSString *, id> *> *__ljbm_hookBusinessInfo = nil;

@implementation LJBenchmark

+ (void)setBenchmarkAvailable:(BOOL)available {
    ljbm_benchmarkAvailable = available;
}

+ (void)addHookClass:(Class)_cls {
    if (NULL == _cls) {
        return;
    }
    if (!ljbm_whiteList) {
        ljbm_whiteList = [NSMutableSet set];
        [self setBenchmarkAvailable:YES];
    }
    [ljbm_whiteList addObject:NSStringFromClass(_cls)];
}

+ (void)addHookClassName:(NSString *)_name {
    if (!_name || !_name.length) {
        return;
    }
    if (!ljbm_whiteList) {
        ljbm_whiteList = [NSMutableSet set];
        [self setBenchmarkAvailable:YES];
    }
    [ljbm_whiteList addObject:_name];
}

+ (void)cancelHookClass:(Class)_cls {
    if (ljbm_whiteList) {
        [ljbm_whiteList removeObject:NSStringFromClass(_cls)];
    }
}

+ (void)filtLogTimeGreaterThan:(double)millisecond {
    ljbm_filtLogTime = millisecond;
}

+ (void)addSelToBlacklist:(SEL)_sel {
    if (!ljbm_blacklist) {
        ljbm_blacklist = __ljbm_default_blacklist;
    }
    [ljbm_blacklist addObject:NSStringFromSelector(_sel)];
}

+ (void)addSelOfClassToBlacklist:(Class)_cls sel:(SEL)_sel {
    if (NULL == _cls || NULL == _sel) {
        return;
    }
    if (!ljbm_Cls_Sel_dic) {
        ljbm_Cls_Sel_dic = [NSMutableDictionary dictionary];
    }
    NSString *clsName = NSStringFromClass(_cls);
    NSString *selName = NSStringFromSelector(_sel);
    NSMutableSet *selSet = [ljbm_Cls_Sel_dic objectForKey:clsName];
    if (!selSet) {
        selSet = [NSMutableSet set];
        [ljbm_Cls_Sel_dic setObject:selSet forKey:clsName];
    }
    [selSet addObject:selName];
}

+ (NSMutableArray<NSDictionary<NSString *, id> *> *)getHookBusinessesInfo {
    if (!__ljbm_hookBusinessInfo) {
        __ljbm_hookBusinessInfo = [NSMutableArray array];
    }
    return __ljbm_hookBusinessInfo;
}

// 通过类名获取类被Hook的业务仓库信息
+ (NSDictionary<NSString *, id> *)getClsBusinessInfo:(NSString *)clsName {
    NSMutableArray<NSDictionary<NSString *, id> *> * businessList = [self getHookBusinessesInfo];
    if (1 == businessList.count) {  // 如果检测的仅有一个lib
        return [businessList.firstObject objectForKey:kLJBenchmarkLogLibNameKey];
    }
    if (0 == businessList.count) {
        return nil;
    }
    // 检测的业务有两个及其以上
    __block NSDictionary *libInfo = nil;
    NSInteger lastBreakIdx = businessList.count - 2;
    [businessList enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableSet<NSString *> *set = [obj objectForKey:kLJBenchmarkLogLibClassesKey];
        BOOL contain = [set containsObject:clsName];
        if (contain) {
            libInfo = [obj objectForKey:kLJBenchmarkLogLibNameKey];
            *stop = YES;
        }
        else if (lastBreakIdx == idx) {  // 加速找到
            libInfo = [businessList.lastObject objectForKey:kLJBenchmarkLogLibNameKey];
            *stop = YES;
        }
        else {
            
        }
    }];
    return libInfo;
}


@end

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

@interface NSObject (LJBenchmark)
- (instancetype)ljbm_init_benchmark_hook NS_UNAVAILABLE;
@end

@implementation NSObject (LJBenchmark)

// 判断方法是否在黑名单中
static BOOL ljbm_hookSelInBlacklist(SEL _sel) {
    if (!ljbm_blacklist) {
        ljbm_blacklist = __ljbm_default_blacklist;
    }
    NSString *selName = NSStringFromSelector(_sel);
    if ([ljbm_blacklist containsObject:selName]) {
        return YES;
    } else if ([selName hasPrefix:@"init"]){
        return YES;
    }
    else {
        return NO;
    }
}

// 方法交换
static void ljbm_swizzleInstanceMethod(Class cls_, SEL origSel_, SEL swizzledSel_) {
    Method originalMethod = class_getInstanceMethod(cls_, origSel_);
    Method swizzledMethod = class_getInstanceMethod(cls_, swizzledSel_);
    BOOL didAddMethod = class_addMethod(cls_,
                                        origSel_,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(cls_,
                            swizzledSel_,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


#if DEBUG

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ljbm_swizzleInstanceMethod(NSObject.class, @selector(init), @selector(ljbm_init_benchmark_hook));
    });
}

#endif

- (instancetype)ljbm_init_benchmark_hook {
    if (ljbm_benchmarkAvailable && ljbm_whiteList && [ljbm_whiteList containsObject:NSStringFromClass(self.class)])
    {
        [self ljbm_hookAllSels];
    }
    return [self ljbm_init_benchmark_hook];
}


/**
 https://github.com/steipete/Aspects
 
 Aspects calls and matches block arguments. Blocks without arguments are supported as well.
 The first block argument will be of type id<AspectInfo>.
 
 [_singleTapGesture aspect_hookSelector:@selector(setState:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
 NSLog(@"%@: %@", aspectInfo.instance, aspectInfo.arguments);
 } error:NULL];
 
 */
- (void)ljbm_hookWithSel:(SEL)_sel {
    NSString *selName = NSStringFromSelector(_sel);
    NSString *clsName = NSStringFromClass(self.class);
    NSString *desc = [NSString stringWithFormat:@"-[%@ %@]", clsName, selName];
    
    NSMutableDictionary *passedDic = [NSMutableDictionary dictionaryWithCapacity:6];
    [passedDic setObject:desc forKey:kLJBenchmarkLogDescKey];
    [passedDic setObject:clsName forKey:kLJBenchmarkLogClsKey];
    [passedDic setObject:selName forKey:kLJBenchmarkLogSelKey];
    [passedDic setObject:@"0" forKey:kLJBenchmarkLogDurationKey];
    
    __block CFTimeInterval startTime = 0;
    __block struct timeval t0, t1;
    
    [self ljaspect_hookSelector:_sel
                  withOptions:LJAspectPositionBefore
                   usingBlock:^(id<LJAspectInfo> info){
                       
                       gettimeofday(&t0, NULL);
                       startTime = (double)(t0.tv_sec) * 1e3 + (double)(t0.tv_usec) * 1e-3;
                       safe_task_queue(^{
                           [passedDic setObject:[NSNumber numberWithDouble:startTime] forKey:kLJBenchmarkLogStartKey];
                       });
                   }
                        error:NULL];
    
    [self ljaspect_hookSelector:_sel
                  withOptions:LJAspectPositionAfter
                   usingBlock:^(id<LJAspectInfo> info){
                       gettimeofday(&t1, NULL);
                       double endTime = (double)(t1.tv_sec) * 1e3 + (double)(t1.tv_usec) * 1e-3;
                       safe_task_queue(^{
                           [passedDic setObject:[NSNumber numberWithDouble:endTime] forKey:kLJBenchmarkLogEndKey];
                           [passedDic setObject:[NSNumber numberWithDouble:ljbm_filtLogTime] forKey:kLJBenchmarkLogFiltTimeKey];
                           
                           [[LJBenchmarkTaskManager sharedInstance] addTimeDic:[passedDic mutableCopy]];
                       });
                       
                   }
                        error:NULL];
}

- (void)ljbm_hookAllSels {
    
    Class cls = self.class;
    
    /*
     由于开发习惯导致重写getter && setter方法
     导致getter方法调用比较频繁，为不比较交换
     所以从hook方法列表中剔除
     */
    NSMutableSet<NSString *> *propertySelNamesSet = nil;
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    if (properties) {
        propertySelNamesSet = [NSMutableSet set];
        for (unsigned int i = 0; i < propertyCount; i++) {
            LJClassPropertyInfo *info = [[LJClassPropertyInfo alloc] initWithProperty:properties[i]];
            if (info.setter != NULL) {
                [propertySelNamesSet addObject:NSStringFromSelector(info.setter)];
            }
            if (info.getter != NULL) {
                [propertySelNamesSet addObject:NSStringFromSelector(info.getter)];
            }
        }
        free(properties);
    }
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (methods) {
        for (unsigned int i = 0; i < methodCount; i++) {
            Method method = methods[i];
            LJClassMethodInfo *info = [[LJClassMethodInfo alloc] initWithMethod:method];
            /*
             !apsects not support struct return type hook
             */
            if ([info.returnTypeEncoding hasPrefix:@"{"] && [info.returnTypeEncoding hasSuffix:@"}"]) {
                continue;
            }
            SEL _sel = method_getName(method);
            if (![self isSelInBlackList:_sel]) {
                if (!propertySelNamesSet || ![propertySelNamesSet containsObject:NSStringFromSelector(_sel)]) {
                    [self ljbm_hookWithSel:_sel];
                }
            }
        }
        free(methods);
    }
}

// 查询某个方法是否在黑名单中
- (BOOL)isSelInBlackList:(SEL) _sel{
    BOOL isBlack = ljbm_hookSelInBlacklist(_sel);
    if (isBlack) {
        return YES;
    }
    if (!ljbm_Cls_Sel_dic) {
        return NO;
    }
    
    NSString *clsName = NSStringFromClass(self.class);
    NSMutableSet<NSString *> *selSet = [ljbm_Cls_Sel_dic objectForKey:clsName];
    
    if (!selSet) {
        return NO;
    }
    
    if ([selSet containsObject:NSStringFromSelector(_sel)]) {
        return YES;
    }
    return NO;
}

@end
