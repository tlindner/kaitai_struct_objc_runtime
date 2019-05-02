#ifndef KAITAI_STRUCT_H
#define KAITAI_STRUCT_H

#import <Cocoa/Cocoa.h>
#import "kaitaistream.h"

@interface kstruct : NSObject
{

}

- (instancetype)init;
- (instancetype)initWith:(kstream *)p__io withStruct:(kstruct *)p__parent withRoot: (kstruct *)p__root withEndian:(int)p__endian NS_DESIGNATED_INITIALIZER;
- (instancetype)initWith:(kstream *)p__io withStruct:(kstruct *)p__parent withRoot: (kstruct *)p__root;
- (void)_read;
- (void)_read_le;
- (void)_read_be;

@property (strong,nonatomic) kstream *_io;
@property (strong,nonatomic) kstruct *_parent;
@property (strong,nonatomic) kstruct *_root;
@property int _is_le;

@end


#endif
