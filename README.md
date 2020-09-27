# LJBenchmark
* 一种简单的方式可对运行时对象方法耗时的检测。
* 一种简单的手段可对APP性能瓶颈的直观的定位。
* 独立的，自闭合Development pod配置环境以及面向切面的思想（AOP）达到了监控与业务的解耦合。
* 支持对方法耗时数据的接收和上传，方便对数据的深度分析挖掘。
* 方便的脚本支持，一键安装、一键清除。

## 1.接入
### 1.1 链接业务监控

可CocoaPods直接引入

```ruby
pod 'LJBenchmark'
```
但是我们更加推荐使用脚本方式接入，
下载github仓库路径下的
[/LJBenchmark/LJBenchmark/Classes/Workspace/benchmark](https://github.com/LianjiaTech/benchmark/blob/master/LJBenchmark/Classes/Workspace/benchmark) 
此文件为脚本文件。
脚本拖入您的工作仓库，也就是Podfile文件同级目录，然后，cd 到该目录下，命令行执行：
```shell
sh benchmark connect [file/dir/podspec_s_name]
```
安装完成以后，执行 Command+R运行项目，即可达到对 [file/dir/podspec_s_name] 描述的业务中函数方法耗时的实时监控。

如果您遇到，sed相关的错误，比如：
```shell
sed: -e expression #1, char 1: unknown command: `_’
sed: can not read …   
```
不要担心，这是Mac的shell和Linux shell差异造成的,只需要更新下设置即可，或者直接下载使用我们gnu版本的shell脚本。

`可参考链接：` <https://www.sunshines.cc/tech/2018/10/26/sed-on-mac/>

### 1.2数据接收

在设计LJBenchmark过程中我们对于耗时数据是直接放到RunLoop空闲状态下来处理的。

```objc
OBJC_EXPORT NSString * const kLJBenchmarkLogNotification;
```
此时我们会发送上述的通知，使用时可自行接收该通知，进行耗时数据展示的自定义。

### 1.3移除业务监控

```shell
sh benchmark clear [file/dir/podspec_s_name]
```

这时候脚本会将1.1中的接入的业务监控相关的设置从你的开发环境移除。

### 1.4获取帮助
更多使用细节可执行如下命令行
```shell
sh benchmark --help
```

## 2.项目结构

![snapshot](https://github.com/LianjiaTech/benchmark/raw/master/Snapshots/project_mind.png)

### 2.1 OC类设计

- **LJAspects可参考**：<https://github.com/steipete/Aspects>
- **LJClassInfo 可参考**：<https://github.com/ibireme/YYModel>

- **NSObject (LJBenchmark)**:采用MethodSwizzling技术手段hook了所有iOS对象的-init方法。

- **LJBenchmarkTaskManager**:主要是对对象方法执行耗时信息进行内存的缓存和管理。

- **LJBenchmark**:主要是对检测工具的一些配置设置相关。

```objc

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ljbm_swizzleInstanceMethod(NSObject.class, @selector(init), @selector(ljbm_init_benchmark_hook));
    });
}

- (instancetype)ljbm_init_benchmark_hook {
    if (ljbm_benchmarkAvailable && ljbm_whiteList && [ljbm_whiteList containsObject:NSStringFromClass(self.class)])
    {
        [self ljbm_hookAllSels];
    }
    return [self ljbm_init_benchmark_hook];
}

```


在实际开发过程中属性方法的getter和Setter会被频繁的调用，多为系统自动编译生成，
所以在 **- ljbm_hookAllSels**  方法中使用 **LJClassInfo** 在运行时取得了该对象的对象方法列表和属性getter和setter方法集合的差集。

```objc

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

```

并在 **- ljbm_hookWithSel** 使用 **LJAspects** 的对象方法进行了统一的hook

```objc

- (id<LJAspectToken>)ljaspect_hookSelector:(SEL)selector
                               withOptions:(LJAspectOptions)options
                                usingBlock:(id)block
                                     error:(NSError **)error;

```

我们在方法执行前  **LJAspectPositionBefore** 和方法执行后 **LJAspectPositionAfter** 将方法执行的相关信息，
通过 **LJBenchmarkTaskManager**这个类进行内存的缓存和管理，在主线程runloop空闲的时候将信息输出。

```objc

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
                       config_add_task_queue(^{
                           [passedDic setObject:[NSNumber numberWithDouble:startTime] forKey:kLJBenchmarkLogStartKey];
                       });
                   }
                        error:NULL];
    
    [self ljaspect_hookSelector:_sel
                  withOptions:LJAspectPositionAfter
                   usingBlock:^(id<LJAspectInfo> info){
                       gettimeofday(&t1, NULL);
                       double endTime = (double)(t1.tv_sec) * 1e3 + (double)(t1.tv_usec) * 1e-3;
                       config_add_task_queue(^{
                           [passedDic setObject:[NSNumber numberWithDouble:endTime] forKey:kLJBenchmarkLogEndKey];
                           [passedDic setObject:[NSNumber numberWithDouble:ljbm_filtLogTime] forKey:kLJBenchmarkLogFiltTimeKey];
                           
                           [[LJBenchmarkTaskManager sharedInstance] addTimeDic:[passedDic mutableCopy]];
                       });
                       
                   }
                        error:NULL];
}

```

- **LJBMUserCustomConfiguration**：一些用户想自定义的设置可在此进行

```objc

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

```

- **目录结构看LJBenchmark**：

![snapshot](https://github.com/LianjiaTech/benchmark/raw/master/Snapshots/project_dir.png)

用户的自定义配置和对数据的接收以及输出完全是在 **Development Pods** 下单独的
**LJBenchmark** 项目下自我闭合的管理的，用户的所有使用过程中，不会存在着对业务代码的直接侵入。

### 2.2 脚本设计

-**help**：帮助脚本

-**pod**：pod相关的自动化管理脚本

-**list**：所有插件的查询脚本

-**connect**：自动链接业务并配置监控的脚本

-**clear**：自动清理业务监控配置的脚本

上述脚本均以插件挂载在 [benchmark](https://github.com/LianjiaTech/benchmark/blob/master/LJBenchmark/Classes/Workspace/benchmark) 脚本下作为operation被执行。

脚本的统一执行格式为

```shell
sh benchmark [operation] [source] [options]
```

*operation*：目前暂定义为help、pod、list、connect、clear。

*source* 通常为输入源，比如文件夹、文件或者podsepc名称代表的仓库等。

*options* 通常为可选项，由 *operation* 的行为定义的可选传入参数。

## 3.使用示例

- **为什么推荐使用脚本** [benchmark](https://github.com/LianjiaTech/benchmark/blob/master/LJBenchmark/Classes/Workspace/benchmark) **接入？**

这时候脚本会自动帮你布置初始化环境，分析你的业务版本信息和所有的类信息，并加载到日志中。
![snapshot](https://github.com/LianjiaTech/benchmark/raw/master/Snapshots/auto_temp.png)
这对后继深度的进行版本性能优化对比分析的场景可能是有用的。

- **log打印日志查看分析**

假设我们发现某处页面打开时候加载比较缓慢或者卡顿，这时候我们的工具就能派上用场了。
下面是一个发现页面加载时长的场景的简化示例：
![snapshot](https://github.com/LianjiaTech/benchmark/raw/master/Snapshots/demo_before.png)

优化前我们发现 **- viewdidload** 该方法加载耗时比较严重。那么从调用栈的角度往上查找，会发现有取缓存数据的一个函数
耗时比较多。我们很直观的就发现了问题的所在，即在主线程中读取缓存然后渲染视图，并不是一个很好的选择。
改用异步线程读取缓存优化以后，实际真机体验取得了良好的效果。再用 `LJBenchmark`  观察页面加载数据:
![snapshot](https://github.com/LianjiaTech/benchmark/raw/master/Snapshots/demo_after.png)

不难看出，LJBenchmark对于函数耗时的分析，将有助于卡顿和延迟问题的快速定位和解决。











