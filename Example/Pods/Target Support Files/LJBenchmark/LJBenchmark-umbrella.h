#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "LJAspects.h"
#import "LJBenchmark.h"
#import "LJBenchmarkTaskManager.h"
#import "LJClassInfo.h"

FOUNDATION_EXPORT double LJBenchmarkVersionNumber;
FOUNDATION_EXPORT const unsigned char LJBenchmarkVersionString[];

