#import "kaitaistruct.h"

#include <machine/endian.h>
#include <libkern/OSByteOrder.h>

#ifdef KS_ZLIB
#include <zlib.h>
#define ZLIB_BUF_SIZE 128 * 1024
#endif

uint64_t kaitai_kstream_get_mask_ones(unsigned long n);

@interface kstream ()

@property (readwrite) unsigned long long pos;
@property (readwrite) unsigned long long size;
@property (strong) NSFileHandle *fh;
@property (strong) NSData *dh;
@property NSUInteger m_bits_left;
@property NSUInteger m_bits;

@end

@implementation kstream
@dynamic pos;
@dynamic eof;

+ (kstream *)streamWithURL:(NSURL *)url
{
    NSError *myErr;
    NSFileHandle *io = [NSFileHandle fileHandleForReadingFromURL:url error: &myErr];

    if (io) {
        return [[kstream alloc] initWithFileHandle:io];
    }
    else {
        [NSException raise:@"Count not Open URL" format:@"%@", myErr];
    }

    return nil;
}

+ (kstream *)streamWithFileHandle:(NSFileHandle *)io
{
    return [[kstream alloc] initWithFileHandle:io];
}

+ (kstream *)streamWithData:(NSData *)data
{
    return [[kstream alloc] initWithData:data];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self alignToByte];
    }

    return self;
}

- (kstream *)initWithFileHandle:(NSFileHandle *)io
{
    self.fh = io;
    self.size = [io seekToEndOfFile];
    [io seekToFileOffset:0];

    return [self init];
}

- (kstream *)initWithData:(NSData *)data
{
    self.dh = data;
    self.size = data.length;

    return [self init];
}

#pragma mark Stream positioning

- (unsigned long long)pos
{
    if (self.dh) {
        return _pos;
    }
    else {
        return self.fh.offsetInFile;
    }
}

-(void)setPos:(unsigned long long)p_pos
{
    [self seek:p_pos];
}

- (BOOL)isEof
{
    if (self.dh) {
        if (_pos >= self.size) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else
    {
        if (self.fh.offsetInFile >= self.size) {
            return YES;
        }
        else {
            return NO;
        }
    }
}

- (void)seek:(unsigned long long)pos
{
    if (self.dh) {
        _pos = pos;

        if (_pos > self.size) _pos = self.size;
    } else {
        [self.fh seekToFileOffset:pos];
    }
}

#pragma mark Integer numbers

- (NSNumber *) read_s1
{
    char t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 1;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:1]) getBytes:&t range:NSMakeRange(v_pos, 1)];

    return @(t);
}

#pragma mark Big-endian

- (NSNumber *) read_s2be
{
    int16_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 2;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:2]) getBytes:&t range:NSMakeRange(v_pos, 2)];

#if BYTE_ORDER == LITTLE_ENDIAN
    t = _OSSwapInt16(t);
#endif

    return @(t);
}

- (NSNumber *) read_s4be
{
    int32_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 4;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:4]) getBytes:&t range:NSMakeRange(v_pos, 4)];

#if BYTE_ORDER == LITTLE_ENDIAN
    t = _OSSwapInt32(t);
#endif

    return @(t);
}

- (NSNumber *) read_s8be
{
    int64_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 8;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:8]) getBytes:&t range:NSMakeRange(v_pos, 8)];


#if BYTE_ORDER == LITTLE_ENDIAN
    t = _OSSwapInt64(t);
#endif

    return @(t);
}

#pragma mark Little-endian
- (NSNumber *) read_s2le
{
    int16_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 2;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:2]) getBytes:&t range:NSMakeRange(v_pos, 2)];

#if BYTE_ORDER == BIG_ENDIAN
    t = _OSSwapInt16(t);
#endif

    return @(t);
}

- (NSNumber *) read_s4le
{
    int32_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 4;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:4]) getBytes:&t range:NSMakeRange(v_pos, 4)];

#if BYTE_ORDER == BIG_ENDIAN
    t = _OSSwapInt32(t);
#endif

    return @(t);
}

- (NSNumber *) read_s8le
{
    int64_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 8;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:8]) getBytes:&t range:NSMakeRange(v_pos, 8)];

#if BYTE_ORDER == BIG_ENDIAN
    t = _OSSwapInt64(t);
#endif

    return @(t);
}

#pragma mark Unsigned

- (NSNumber *) read_u1
{
    unsigned char t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 1;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:1]) getBytes:&t range:NSMakeRange(v_pos, 1)];

    return @(t);
}

#pragma mark Big-endian

- (NSNumber *) read_u2be
{
    uint16_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 2;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:2]) getBytes:&t range:NSMakeRange(v_pos, 2)];

#if BYTE_ORDER == LITTLE_ENDIAN
    t = _OSSwapInt16(t);
#endif

    return @(t);
}

- (NSNumber *) read_u4be
{
    uint32_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 4;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:4]) getBytes:&t range:NSMakeRange(v_pos, 4)];

#if BYTE_ORDER == LITTLE_ENDIAN
    t = _OSSwapInt32(t);
#endif

    return @(t);
}

- (NSNumber *) read_u8be
{
    uint64_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 8;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:8]) getBytes:&t range:NSMakeRange(v_pos, 8)];

#if BYTE_ORDER == LITTLE_ENDIAN
    t = _OSSwapInt64(t);
#endif

    return @(t);
}

#pragma mark Little-endian

- (NSNumber *) read_u2le
{
    uint16_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 2;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:2]) getBytes:&t range:NSMakeRange(v_pos, 2)];

#if BYTE_ORDER == BIG_ENDIAN
    t = _OSSwapInt16(t);
#endif

    return @(t);
}

- (NSNumber *) read_u4le
{
    uint32_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 4;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:4]) getBytes:&t range:NSMakeRange(v_pos, 4)];

#if BYTE_ORDER == BIG_ENDIAN
    t = _OSSwapInt32(t);
#endif

    return @(t);
}

- (NSNumber *) read_u8le
{
    uint64_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 8;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:8]) getBytes:&t range:NSMakeRange(v_pos, 8)];

#if BYTE_ORDER == BIG_ENDIAN
    t = _OSSwapInt64(t);
#endif

    return @(t);
}

#pragma mark Floating point numbers
#pragma mark Big-endian

- (NSNumber *) read_f4be
{
    uint32_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 4;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:4]) getBytes:&t range:NSMakeRange(v_pos, 4)];

#if BYTE_ORDER == LITTLE_ENDIAN
    t = _OSSwapInt32(t);
#endif

    float *f = (float *)&t;
    return @(*f);
}

- (NSNumber *) read_f8be
{
    uint64_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 8;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:8]) getBytes:&t range:NSMakeRange(v_pos, 8)];

#if BYTE_ORDER == LITTLE_ENDIAN
    t = _OSSwapInt64(t);
#endif

    double *d = (double *)&t;
    return @(*d);
}

#pragma mark Little-endian

- (NSNumber *) read_f4le
{
    uint32_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 4;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:4]) getBytes:&t range:NSMakeRange(v_pos, 4)];

#if BYTE_ORDER == BIG_ENDIAN
    t = _OSSwapInt32(t);
#endif

    float *f = (float *)&t;
    return @(*f);
}

- (NSNumber *) read_f8le
{
    uint64_t t;
    NSUInteger v_pos;

    if (self.dh) {
        v_pos = _pos;
        _pos += 8;
    } else {
        v_pos = 0;
    }

    [(self.dh ? self.dh : [self.fh readDataOfLength:8]) getBytes:&t range:NSMakeRange(v_pos, 8)];

#if BYTE_ORDER == BIG_ENDIAN
    t = _OSSwapInt64(t);
#endif

    double *d = (double *)&t;
    return @(*d);
}

#pragma mark Unaligned bit values

-(void)alignToByte
{
    self.m_bits_left = 0;
    self.m_bits = 0;
}

-(NSNumber *)read_bits_int:(NSUInteger)n
{
    unsigned long bits_needed = n - self.m_bits_left;
    if (bits_needed > 0) {
        // 1 bit  => 1 byte
        // 8 bits => 1 byte
        // 9 bits => 2 bytes
        unsigned long bytes_needed = ((bits_needed - 1) / 8) + 1;
        if (bytes_needed > 8) {
            NSException *myException = [NSException exceptionWithName:@"read_bits_int: more than 8 bytes requested" reason:nil userInfo:nil];
            @throw myException;
        }
        char *buf;
        NSUInteger v_pos;

        if (self.dh) {
            v_pos = _pos;
            _pos += bytes_needed;
        } else {
            v_pos = 0;
        }

        [(self.dh ? self.dh : [self.fh readDataOfLength:bytes_needed]) getBytes:&buf range:NSMakeRange(v_pos, bytes_needed)];

        for (int i = 0; i < bytes_needed; i++) {
            uint8_t b = buf[i];
            self.m_bits <<= 8;
            self.m_bits |= b;
            self.m_bits_left += 8;
        }
    }

    // raw mask with required number of 1s, starting from lowest bit
    uint64_t mask = kaitai_kstream_get_mask_ones(n);
    // shift mask to align with highest bits available in @bits
    unsigned long shift_bits = self.m_bits_left - n;
    mask <<= shift_bits;
    // derive reading result
    uint64_t res = (self.m_bits & mask) >> shift_bits;
    // clear top bits that we've just read => AND with 1s
    self.m_bits_left -= n;
    mask = kaitai_kstream_get_mask_ones(self.m_bits_left);
    self.m_bits &= mask;

    return [NSNumber numberWithUnsignedLong:res];
}

#pragma mark Byte arrays

-(NSData *)read_bytes:(NSUInteger)len
{
    NSData *result;

    if (self.dh) {
        result = [self.dh subdataWithRange:NSMakeRange(_pos, len)];
        _pos += len;
    } else {
        result = [self.fh readDataOfLength:len];
    }

    [kstream throwIf:result smallerThan:len];

    return result;
}

-(NSData *)read_bytes_full
{
    NSData *result;

    if (self.dh) {
        NSRange range = NSMakeRange(_pos, self.size - _pos);
        result = [self.dh subdataWithRange:range];
        _pos = self.size;
    } else {
        result = [self.fh readDataToEndOfFile];
    }

    return result;
}

-(NSData *)read_bytes_term:(char)character include:(BOOL)include consume:(BOOL)consume eosErr:(BOOL)eos_error
{
    NSData *result;
    unsigned long long start = _pos;

    if (self.dh) {
        const char *buf = &(self.dh.bytes[_pos]);
        while( _pos < self.size )
        {
            if(buf[_pos++] == character) break;
        }

        if (_pos == self.size) {
            if (eos_error) {
                NSException *myException = [NSException exceptionWithName:@"read_bytes_term: encountered EOF" reason:nil userInfo:nil];
                @throw myException;
            }
        }

        NSRange range = NSMakeRange(start, start - _pos - (include ? 0 : 1));
        result = [self.dh subdataWithRange:range];

        if (!consume)
            _pos = _pos - 1;

    } else {
        NSMutableData *buffer = [NSMutableData data];
        NSData *temp;

        while((temp = [self.fh readDataOfLength:1]))
        {
            if (temp.length == 0) {
                if (eos_error) {
                    NSException *myException = [NSException exceptionWithName:@"read_bytes_term: encountered EOF" reason:nil userInfo:nil];
                    @throw myException;
                }
                break;
            }

            char t = ((char *)temp.bytes)[0];
            if (t == character) {
                if(include) [buffer appendData:temp];
                break;
            }

            [buffer appendData:temp];
        }

        if (!consume) [self.fh seekToFileOffset:self.fh.offsetInFile-1];

        result = buffer;
    }

    return result;
}

-(NSData *)ensure_fixed_contents:(NSData *)expected
{
    NSData *actual = [self read_bytes:expected.length];

    if (![actual isEqualToData:expected]) {
        NSException *myException = [NSException exceptionWithName:@"ensure_fixed_contents: actual data does not match expected data" reason:nil userInfo:nil];
        @throw myException;
    }

    return actual;
}

- (NSData *)reverse:(NSData *)val
{
    const char *bytes = val.bytes;

    NSUInteger datalength = val.length;

    char *reverseBytes = malloc(sizeof(char) * datalength);
    NSUInteger index = datalength - 1;

    for (int i = 0; i < datalength; i++)
        reverseBytes[index--] = bytes[i];

    return [NSData dataWithBytesNoCopy:reverseBytes length: datalength];
}

+ (void) throwIf:(NSData *)t smallerThan:(NSUInteger)v
{
    if (t.length < v) {
        NSException *myException = [NSException exceptionWithName:[NSString stringWithFormat:@"smaller than expected read: %lu < %lu", (unsigned long)t.length, (unsigned long)v] reason:nil userInfo:nil];
        @throw myException;
    }
}

+(int) modA:(int)a b:(int)b;
{
    if (b <= 0)
        [NSException raise:@"modulus b <= 0" format:@""];
    int r = a % b;
    if (r < 0)
        r += b;
    return r;
}

@end

@implementation kstruct

- (instancetype)init
{
    self = [self initWith:nil withStruct:nil withRoot:nil];
    if (self) {
    }
    return self;

}

- (instancetype) initWith:(kstream *)p__io withStruct:(kstruct *)p__parent withRoot:(kstruct *)p__root
{
    self = [super init];
    if (self) {
        self._io = p__io;
        self._parent = p__parent;

        if (p__root == nil) {
            self._root = self;
        }
        else {
            self._root = p__root;
        }
     }

    return self;
}

- (void)_read
{
    [NSException raise:@"runtime error: _read needs to be implented in subclass" format:@""];
}

- (void)_read_le
{
    [NSException raise:@"runtime error: _read_le needs to be implented in subclass" format:@""];
}

- (void)_read_be
{
    [NSException raise:@"runtime error: _read_be needs to be implented in subclass" format:@""];
}

@end

uint64_t kaitai_kstream_get_mask_ones(unsigned long n) {
    if (n == 64) {
        return 0xFFFFFFFFFFFFFFFF;
    } else {
        return ((uint64_t) 1 << n) - 1;
    }
}

@implementation NSString (KSStringPrivateMethods)

- (NSNumber *)ksToNumberWithBase:(int)base
{
    if (base == 10) {
        return @(self.intValue);
    } else {
        return @(strtol(self.UTF8String, NULL, base));
    }
}

- (NSString *)ksReverse
{
    /* https://stackoverflow.com/a/6720235 */
    NSMutableString *reversedString = [NSMutableString string];
    NSInteger charIndex = [self length];
    NSRange subStrRange = {0, 1};
    while (charIndex > 0) {
        charIndex--;
        subStrRange.location = charIndex;
        [reversedString appendString:[self substringWithRange:subStrRange]];
    }
    return reversedString;
}

- (NSDictionary *)KSENUMWithDictionary:(NSDictionary *)dictionary
{
    id result = [dictionary objectForKey:self];
    if(result==nil) result = [NSNull null];
    return @{ @"enum" : self, @"value" : result };
}
@end

@implementation NSData (KSDataPrivateMethods)

- (NSString *)KSBytesToStringWithEncoding:(NSString *)src_enc
{
    NSStringEncoding e = NSUTF8StringEncoding;
    NSString *lc_enc =src_enc.lowercaseString;

    if ([lc_enc isEqualToString:@"ascii"]) {
        e = NSMacOSRomanStringEncoding; /* OS X's ASCII is strictly 7 bit */
    } else if ([lc_enc isEqualToString:@"utf-8"]) {
        e = NSUTF8StringEncoding;
    } else if ([lc_enc isEqualToString:@"utf-16le"]) {
        e = NSUTF16LittleEndianStringEncoding;
    } else if ([lc_enc isEqualToString:@"utf-16be"]) {
        e = NSUTF16BigEndianStringEncoding;
    } else {
        [NSException raise:@"unsupported string encoding" format:@"unsupported string encoding: %@", lc_enc];
    }

    return [[NSString alloc] initWithData:self encoding:e];
}

- (NSData *)KSReverse
{
    /* https://stackoverflow.com/a/27152342 */
    NSMutableData *data = [[NSMutableData alloc] init];
    for(int i = (int)self.length - 1; i >=0; i--){
        [data appendBytes: &self.bytes[i] length:1];
    }
    return data;
}

- (NSData *)KSProcessXorOneWithKey:(uint8_t)key
{
    size_t len = self.length;
    unsigned char *buf = malloc(len);

    if (!buf) {
        NSException *myException = [NSException exceptionWithName:@"process_xor_one: out of memory" reason:nil userInfo:nil];
        @throw myException;
    }

    unsigned char *src = (unsigned char *)self.bytes;

    for (size_t i = 0; i < len; i++)
        buf[i] = src[i] ^ key;

    return [NSData dataWithBytesNoCopy:buf length:len];
}

- (NSData *)KSProcessXorManyWithKey:(NSData *)key
{
    size_t len = self.length;
    size_t kl = key.length;
    unsigned char *self_buf = (unsigned char *)self.bytes;
    unsigned char *key_buf = (unsigned char *)key.bytes;

    unsigned char *buf = malloc(len);

    if (!buf) {
        NSException *myException = [NSException exceptionWithName:@"process_xor_many: out of memory" reason:nil userInfo:nil];
        @throw myException;
    }

    size_t ki = 0;
    for (size_t i = 0; i < len; i++) {
        buf[i] = self_buf[i] ^ key_buf[ki];
        ki++;
        if (ki >= kl)
            ki = 0;
    }

    return [NSData dataWithBytesNoCopy:buf length:len];
}

- (int)KSCompare:(NSData *)compare
{
    size_t sl = self.length, cl = compare.length;
    const unsigned char *s = self.bytes, *c = compare.bytes;
    const unsigned char *se = &(s[sl]), *ce = &(c[cl]);

    if(sl==0 && cl==0) return 0;
    if(sl==0) return -1;
    if(cl==0) return 1;

    while(s<se && c<ce) {
        if(*s != *c) return *s - *c;
        s++;
        c++;
    }

    if(sl<cl) return -1;
    if(sl>cl) return 1;

    return 0;
}

- (NSData *)KSProcessRotateLeftWithAmount:(int)amount
{
    size_t len = self.length;
    unsigned char *buf = malloc(len);
    unsigned char *self_buf = (unsigned char *)self.bytes;

    if (!buf) {
        NSException *myException = [NSException exceptionWithName:@"process_rotate_left: out of memory" reason:nil userInfo:nil];
        @throw myException;
    }

    for (size_t i = 0; i < len; i++) {
        uint8_t bits = self_buf[i];
        buf[i] = (bits << amount) | (bits >> (8 - amount));
    }

    return [NSData dataWithBytesNoCopy:buf length:len];
}

- (NSData *)KSBytesStripRightPadByte:(unsigned char)pad_byte
{
    size_t new_len = self.length;
    char *self_ptr = (char *)self.bytes;

    while (new_len > 0 && self_ptr[new_len - 1] == pad_byte)
        new_len--;
    NSRange range = NSMakeRange(0, new_len);
    return [self subdataWithRange:range];
}

- (NSData *)KSBytesTerminateTerm:(char)term include:(BOOL)include;
{
    size_t new_len = 0;
    size_t max_len = self.length;
    char *self_ptr = (char *)self.bytes;

    while (new_len < max_len && self_ptr[new_len] != term)
        new_len++;

    if (include && new_len < max_len)
        new_len++;

    NSRange range = NSMakeRange(0, new_len);
    return [self subdataWithRange:range];
}

#ifdef KS_ZLIB
-(NSData *)KSProcess_zlib
{
    int ret;

    unsigned char *src_ptr = (unsigned char *)self.bytes;

    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;

    ret = inflateInit(&strm);
    if (ret != Z_OK) {
        NSException *myException = [NSException exceptionWithName:@"process_zlib: inflateInit error" reason:nil userInfo:nil];
        @throw myException;
    }

    strm.next_in = src_ptr;
    strm.avail_in = self.length;

    unsigned char outbuffer[ZLIB_BUF_SIZE];
    NSMutableData *outData = [NSMutableData data];

    // get the decompressed bytes blockwise using repeated calls to inflate
    do {
        strm.next_out = outbuffer;
        strm.avail_out = sizeof(outbuffer);

        ret = inflate(&strm, 0);

        if (outData.length < strm.total_out)
            [outData appendData:[NSData dataWithBytes:outbuffer length:strm.total_out - outData.length]];
    } while (ret == Z_OK);

    if (ret != Z_STREAM_END) {          // an error occurred that was not EOF
        NSException *myException = [NSException exceptionWithName:@"process_zlib: Z Lib error" reason:nil userInfo:nil];
        @throw myException;
    }

    if (inflateEnd(&strm) != Z_OK) {
        NSException *myException = [NSException exceptionWithName:@"process_zlib: inflateEnd error" reason:nil userInfo:nil];
        @throw myException;
    }

    return outData;
}
#endif

@end

@implementation NSNumber (KSNumberPrivateMethods)

- (NSDictionary *)KSENUMWithDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in dictionary) {
        if ([dictionary[key] isEqualToNumber:self]) {
            return @{ @"enum" : key, @"value" : self};
        }
    }

    return @{ @"enum" : @"unknown", @"value" : self };
}

@end

@implementation NSDictionary (KSDictionaryENUMPrivateMethods)

- (BOOL) KSIsEqualToENUM:(NSDictionary *)compare
{
    return [self[@"value"] isEqualToNumber:compare[@"value"]];
}
@end
