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
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Type encoding's type.
 */
typedef NS_OPTIONS(NSUInteger, LJEncodingType) {
    LJEncodingTypeMask       = 0xFF, ///< mask of type value
    LJEncodingTypeUnknown    = 0, ///< unknown
    LJEncodingTypeVoid       = 1, ///< void
    LJEncodingTypeBool       = 2, ///< bool
    LJEncodingTypeInt8       = 3, ///< char / BOOL
    LJEncodingTypeUInt8      = 4, ///< unsigned char
    LJEncodingTypeInt16      = 5, ///< short
    LJEncodingTypeUInt16     = 6, ///< unsigned short
    LJEncodingTypeInt32      = 7, ///< int
    LJEncodingTypeUInt32     = 8, ///< unsigned int
    LJEncodingTypeInt64      = 9, ///< long long
    LJEncodingTypeUInt64     = 10, ///< unsigned long long
    LJEncodingTypeFloat      = 11, ///< float
    LJEncodingTypeDouble     = 12, ///< double
    LJEncodingTypeLongDouble = 13, ///< long double
    LJEncodingTypeObject     = 14, ///< id
    LJEncodingTypeClass      = 15, ///< Class
    LJEncodingTypeSEL        = 16, ///< SEL
    LJEncodingTypeBlock      = 17, ///< block
    LJEncodingTypePointer    = 18, ///< void*
    LJEncodingTypeStruct     = 19, ///< struct
    LJEncodingTypeUnion      = 20, ///< union
    LJEncodingTypeCString    = 21, ///< char*
    LJEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    LJEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    LJEncodingTypeQualifierConst  = 1 << 8,  ///< const
    LJEncodingTypeQualifierIn     = 1 << 9,  ///< in
    LJEncodingTypeQualifierInout  = 1 << 10, ///< inout
    LJEncodingTypeQualifierOut    = 1 << 11, ///< out
    LJEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    LJEncodingTypeQualifierByref  = 1 << 13, ///< byref
    LJEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    LJEncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    LJEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    LJEncodingTypePropertyCopy         = 1 << 17, ///< copy
    LJEncodingTypePropertyRetain       = 1 << 18, ///< retain
    LJEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    LJEncodingTypePropertyWeak         = 1 << 20, ///< weak
    LJEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    LJEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    LJEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
};

/**
 Get the type from a Type-Encoding string.
 
 @discussion See also:
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 
 @param typeEncoding  A Type-Encoding string.
 @return The encoding type.
 */
LJEncodingType LJEncodingGetType(const char *typeEncoding);


/**
 Instance variable information.
 */
@interface LJClassIvarInfo : NSObject
@property (nonatomic, assign, readonly) Ivar ivar;              ///< ivar opaque struct
@property (nonatomic, strong, readonly) NSString *name;         ///< Ivar's name
@property (nonatomic, assign, readonly) ptrdiff_t offset;       ///< Ivar's offset
@property (nonatomic, strong, readonly) NSString *typeEncoding; ///< Ivar's type encoding
@property (nonatomic, assign, readonly) LJEncodingType type;    ///< Ivar's type

/**
 Creates and returns an ivar info object.
 
 @param ivar ivar opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithIvar:(Ivar)ivar;
@end


/**
 Method information.
 */
@interface LJClassMethodInfo : NSObject
@property (nonatomic, assign, readonly) Method method;                  ///< method opaque struct
@property (nonatomic, strong, readonly) NSString *name;                 ///< method name
@property (nonatomic, assign, readonly) SEL sel;                        ///< method's selector
@property (nonatomic, assign, readonly) IMP imp;                        ///< method's implementation
@property (nonatomic, strong, readonly) NSString *typeEncoding;         ///< method's parameter and return types
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;   ///< return value's type
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings; ///< array of arguments' type

/**
 Creates and returns a method info object.
 
 @param method method opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithMethod:(Method)method;
@end


/**
 Property information.
 */
@interface LJClassPropertyInfo : NSObject
@property (nonatomic, assign, readonly) objc_property_t property; ///< property's opaque struct
@property (nonatomic, strong, readonly) NSString *name;           ///< property's name
@property (nonatomic, assign, readonly) LJEncodingType type;      ///< property's type
@property (nonatomic, strong, readonly) NSString *typeEncoding;   ///< property's encoding value
@property (nonatomic, strong, readonly) NSString *ivarName;       ///< property's ivar name
@property (nullable, nonatomic, assign, readonly) Class cls;      ///< may be nil
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *protocols; ///< may nil
@property (nonatomic, assign, readonly) SEL getter;               ///< getter (nonnull)
@property (nonatomic, assign, readonly) SEL setter;               ///< setter (nonnull)

/**
 Creates and returns a property info object.
 
 @param property property opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithProperty:(objc_property_t)property;
@end


/**
 Class information for a class.
 */
@interface LJClassInfo : NSObject
@property (nonatomic, assign, readonly) Class cls; ///< class object
@property (nullable, nonatomic, assign, readonly) Class superCls; ///< super class object
@property (nullable, nonatomic, assign, readonly) Class metaCls;  ///< class's meta class object
@property (nonatomic, readonly) BOOL isMeta; ///< whether this class is meta class
@property (nonatomic, strong, readonly) NSString *name; ///< class name
@property (nullable, nonatomic, strong, readonly) LJClassInfo *superClassInfo; ///< super class's class info
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, LJClassIvarInfo *> *ivarInfos; ///< ivars
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, LJClassMethodInfo *> *methodInfos; ///< methods
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, LJClassMethodInfo *> *selfMethodInfos; ///< methods
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, LJClassPropertyInfo *> *propertyInfos; ///< properties

/**
 If the class is changed (for example: you add a method to this class with
 'class_addMethod()'), you should call this method to refresh the class info cache.
 
 After called this method, `needUpdate` will returns `YES`, and you should call 
 'classInfoWithClass' or 'classInfoWithClassName' to get the updated class info.
 */
- (void)setNeedUpdate;

/**
 If this method returns `YES`, you should stop using this instance and call
 `classInfoWithClass` or `classInfoWithClassName` to get the updated class info.
 
 @return Whether this class info need update.
 */
- (BOOL)needUpdate;

/**
 Get the class info of a specified Class.
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 @param cls A class.
 @return A class info, or nil if an error occurs.
 */
+ (nullable instancetype)classInfoWithClass:(Class)cls;

/**
 Get the class info of a specified Class.
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 @param className A class name.
 @return A class info, or nil if an error occurs.
 */
+ (nullable instancetype)classInfoWithClassName:(NSString *)className;

@end

NS_ASSUME_NONNULL_END
