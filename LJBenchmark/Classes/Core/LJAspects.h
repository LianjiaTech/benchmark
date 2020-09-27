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

typedef NS_OPTIONS(NSUInteger, LJAspectOptions) {
    LJAspectPositionAfter   = 0,            /// Called after the original implementation (default)
    LJAspectPositionInstead = 1,            /// Will replace the original implementation.
    LJAspectPositionBefore  = 2,            /// Called before the original implementation.
    
    LJAspectOptionAutomaticRemoval = 1 << 3 /// Will remove the hook after the first execution.
};

/// Opaque Aspect Token that allows to deregister the hook.
@protocol LJAspectToken <NSObject>

/// Deregisters an aspect.
/// @return YES if deregistration is successful, otherwise NO.
- (BOOL)remove;

@end

/// The LJAspectInfo protocol is the first parameter of our block syntax.
@protocol LJAspectInfo <NSObject>

/// The instance that is currently hooked.
- (id)instance;

/// The original invocation of the hooked method.
- (NSInvocation *)originalInvocation;

/// All method arguments, boxed. This is lazily evaluated.
- (NSArray *)arguments;

@end

/**
 Aspects uses Objective-C message forwarding to hook into messages. This will create some overhead. Don't add aspects to methods that are called a lot. Aspects is meant for view/controller code that is not called a 1000 times per second.

 Adding aspects returns an opaque token which can be used to deregister again. All calls are thread safe.
 */
@interface NSObject (LJAspects)

/// Adds a block of code before/instead/after the current `selector` for a specific class.
///
/// @param block Aspects replicates the type signature of the method being hooked.
/// The first parameter will be `id<LJAspectInfo>`, followed by all parameters of the method.
/// These parameters are optional and will be filled to match the block signature.
/// You can even use an empty block, or one that simple gets `id<LJAspectInfo>`.
///
/// @note Hooking static methods is not supported.
/// @return A token which allows to later deregister the aspect.
+ (id<LJAspectToken>)ljaspect_hookSelector:(SEL)selector
                           withOptions:(LJAspectOptions)options
                            usingBlock:(id)block
                                 error:(NSError **)error;

/// Adds a block of code before/instead/after the current `selector` for a specific instance.
- (id<LJAspectToken>)ljaspect_hookSelector:(SEL)selector
                           withOptions:(LJAspectOptions)options
                            usingBlock:(id)block
                                 error:(NSError **)error;

@end


typedef NS_ENUM(NSUInteger, LJAspectErrorCode) {
    LJAspectErrorSelectorBlacklisted,                   /// Selectors like release, retain, autorelease are blacklisted.
    LJAspectErrorDoesNotRespondToSelector,              /// Selector could not be found.
    LJAspectErrorSelectorDeallocPosition,               /// When hooking dealloc, only LJAspectPositionBefore is allowed.
    LJAspectErrorSelectorAlreadyHookedInClassHierarchy, /// Statically hooking the same method in subclasses is not allowed.
    LJAspectErrorFailedToAllocateClassPair,             /// The runtime failed creating a class pair.
    LJAspectErrorMissingBlockSignature,                 /// The block misses compile time signature info and can't be called.
    LJAspectErrorIncompatibleBlockSignature,            /// The block signature does not match the method or is too large.

    LJAspectErrorRemoveObjectAlreadyDeallocated = 100   /// (for removing) The object hooked is already deallocated.
};

extern NSString *const LJAspectErrorDomain;
