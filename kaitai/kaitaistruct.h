#ifndef KAITAI_STRUCT_H
#define KAITAI_STRUCT_H

#import <Cocoa/Cocoa.h>
#import "kaitaistream.h"

@interface kstruct : NSObject
{

}

- (instancetype)init;
- (instancetype)initWith:(kstream *)p__io withStruct:(kstruct *)p__parent withRoot: (kstruct *)p__root NS_DESIGNATED_INITIALIZER;
- (void)_read;
- (void)_read_le;
- (void)_read_be;

@property (strong) kstream *_io;
@property (strong) kstruct *_parent;
@property (strong) kstruct *_root;

@end


#endif
