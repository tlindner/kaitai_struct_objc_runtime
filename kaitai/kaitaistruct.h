#ifndef KAITAI_STRUCT_H
#define KAITAI_STRUCT_H

#import <Cocoa/Cocoa.h>
#import "kaitaistream.h"

@interface KSStruct : NSObject
{

}

- (instancetype)init;
- (instancetype)initWithStream:(KSStream *)p__io;
- (instancetype)initWithStream:(KSStream *)p__io parent:(KSStruct *)p__parent root: (KSStruct *)p__root;
- (instancetype)initWithStream:(KSStream *)p__io parent:(KSStruct *)p__parent root: (KSStruct *)p__root endian:(int)p__endian NS_DESIGNATED_INITIALIZER;
- (void)_read;
- (void)_read_le;
- (void)_read_be;

@property (strong,nonatomic) KSStream *_io;
@property (weak,nonatomic) KSStruct *_parent;
@property (weak,nonatomic) KSStruct *_root;
@property int _is_le;

@end


#endif
