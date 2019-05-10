#ifndef KAITAI_STREAM_H
#define KAITAI_STREAM_H

#import <Cocoa/Cocoa.h>

// Kaitai Struct runtime API version: x.y.z = 'xxxyyyzzz' decimal
#define KAITAI_STRUCT_VERSION 7000L

/**
 * Kaitai Stream class (KSStream) is an implementation of
 * <a href="https://github.com/kaitai-io/kaitai_struct/wiki/Kaitai-Struct-stream-API">
 * Kaitai Struct stream API</a> for Objective-C / Cocoa. It's implemented as a wrapper
 * over NSFileHandle and NSData.
 *
 * It provides a wide variety of simple methods to read (parse) binary
 * representations of primitive types, such as integer and floating
 * point numbers, byte arrays and strings, and also provides stream
 * positioning / navigation methods with unified cross-language and
 * cross-toolkit semantics.
 *
 * Typically, end users won't access Kaitai Stream class manually, but would
 * describe a binary structure format using .ksy language and then would use
 * Kaitai Struct compiler to generate source code in desired target language.
 * That code, in turn, would use this class and API to do the actual parsing
 * job.
 */

@interface KSStream : NSObject
{
    unsigned long long _pos;
}

+ (KSStream *)streamWithURL:(NSURL *)url;
+ (KSStream *)streamWithFileHandle:(NSFileHandle *)io;
+ (KSStream *)streamWithData:(NSData *)data;

    /**
     * Constructs new Kaitai Stream object, wrapping a given std::istream.
     * \param io NSInputStream object to use for this Kaitai Stream
     */
- (KSStream *)initWithFileHandle:(NSFileHandle *)io;

    /**
     * Constructs new Kaitai Stream object, wrapping a given in-memory data
     * buffer.
     * \param data data buffer to use for this Kaitai Stream
     */
- (KSStream *)initWithData:(NSData *)data;

    /**
     * Check if stream pointer is at the end of stream. Note that the semantics
     * are different from traditional STL semantics: one does *not* need to do a
     * read (which will fail) after the actual end of the stream to trigger EOF
     * flag, which can be accessed after that read. It is sufficient to just be
     * at the end of the stream for this method to return true.
     * \return "true" if we are located at the end of the stream.
     */
@property (getter=isEof, readonly) BOOL eof;

    /**
     * Set stream pointer to designated position.
     * \param pos new position (offset in bytes from the beginning of the stream)
     */
- (void)seek:(unsigned long long)pos;

    /**
     * Get current position of a stream pointer.
     * \return pointer position, number of bytes from the beginning of the stream
     */
@property (readonly) unsigned long long pos;

    /**
     * Get total size of the stream in bytes.
     * \return size of the stream in bytes
     */
@property (readonly) unsigned long long size;

#pragma mark Integer numbers

    // ------------------------------------------------------------------------
    // Signed
    // ------------------------------------------------------------------------

@property (readonly) int8_t read_s1;

    // ........................................................................
    // Big-endian
    // ........................................................................

@property (readonly) int16_t read_s2be;
@property (readonly) int32_t read_s4be;
@property (readonly) int64_t read_s8be;

    // ........................................................................
    // Little-endian
    // ........................................................................

@property (readonly) int16_t read_s2le;
@property (readonly) int32_t read_s4le;
@property (readonly) int64_t read_s8le;

    // ------------------------------------------------------------------------
    // Unsigned
    // ------------------------------------------------------------------------

@property (readonly) uint8_t read_u1;

    // ........................................................................
    // Big-endian
    // ........................................................................

@property (readonly) uint16_t read_u2be;
@property (readonly) uint32_t read_u4be;
@property (readonly) uint64_t read_u8be;

    // ........................................................................
    // Little-endian
    // ........................................................................

@property (readonly) uint16_t read_u2le;
@property (readonly) uint32_t read_u4le;
@property (readonly) uint64_t read_u8le;

#pragma mark Floating point numbers

    // ........................................................................
    // Big-endian
    // ........................................................................

@property (readonly) float read_f4be;
@property (readonly) double read_f8be;

    // ........................................................................
    // Little-endian
    // ........................................................................

@property (readonly) float read_f4le;
@property (readonly) double read_f8le;

#pragma mark Unaligned bit values

- (void)alignToByte;
- (uint64_t)readBitsInt:(int)n;

#pragma mark Byte arrays

/**
 * Reads len number of bytes of a stream.
 */
- (NSData *)readBytes:(NSUInteger)len;

/**
 * Reads all the bytes a stream contains.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *readBytesFull;

/**
 * Reads bytes until a terminator is encountered.
 */
- (NSData *)readBytesTerm:(char)character include:(BOOL)include consume:(BOOL)consume eosErr:(BOOL)eos_error;

/**
 * Reads bytes and compares them to a fixed value.
 */
- (NSData *)ensureFixedContents:(NSData *)expected;

/**
 * Throws an exception if an NSData object is not the expected length.
 */
+ (void) throwIf:(NSData *)t shorterThan:(NSUInteger)v;

/**
 * Performs modulo operation between two integers: dividend `a`
 * and divisor `b`. Divisor `b` is expected to be positive. The
 * result is always 0 <= x <= b - 1.
 */
+ (int) modA:(int)a b:(int)b;

@end

@interface NSString (KSStringPrivateMethods)

/**
 * Converts given integer `val` to a decimal string representation.
 * Should be used in place of std::to_string() (which is available only
 * since C++11) in older C++ implementations.
 */
- (NSNumber *)KSToNumberWithBase:(int)base;

/**
 * Reverses given string, so that the first character becomes the
 * last and the last one becomes the first. This should be used to avoid
 * the need of local variables at the caller.
 */
- (NSString *)KSReverse;

- (NSDictionary *)KSENUMWithDictionary:(NSDictionary *)dictionary;

@end

@interface NSData (KSDataPrivateMethods)

- (NSString *)KSBytesToStringWithEncoding:(NSString *)src_enc;

/**
 * Reverses given data, so that the first byte becomes the
 * last and the last one becomes the first. This should be used to avoid
 * the need of local variables at the caller.
 */
- (NSData *)KSReverse;

/**
 * Performs a XOR processing with given data, XORing every byte of input with a single
 * given value.
 * @param key value to XOR with
 * @return processed data
 */
- (NSData *)KSProcessXorOneWithKey:(uint8_t)key;

/**
 * Performs a XOR processing with given data, XORing every byte of input with a key
 * array, repeating key array many times, if necessary (i.e. if data array is longer
 * than key array).
 * @param key array of bytes to XOR with
 * @return processed data
 */
- (NSData *)KSProcessXorManyWithKey:(NSData *)key;

/**
 * Compares two NSData objects.
 * @param compare data to compare with
 * @return -1, 0 or 1
 */
- (int)KSCompare:(NSData *)compare;

/**
 * Performs a circular left rotation shift for a given buffer by a given amount of bits,
 * using groups of 1 bytes each time. Right circular rotation should be performed
 * using this procedure with corrected amount.
 * @param amount number of bits to shift by
 * @return copy of source array with requested shift applied
 */
- (NSData *)KSProcessRotateLeftWithAmount:(int)amount;

/**
 * Removes the pad_byte from the right end of the data.
 * @param pad_byte byte to look for
 * @return copy of data with pad bytes removed
 */
- (NSData *)KSBytesStripRightPadByte:(unsigned char)pad_byte;

/**
 * Looks for termination bytes in data and removes data to the left
 * @param term byte to look for
 * @param include flag to include or exclue the termination byte
 * @return copy of data up to termination byte
 */
- (NSData *)KSBytesTerminateTerm:(char)term include:(BOOL)include;

#ifdef KS_ZLIB
    /**
     * Performs an unpacking ("inflation") of zlib-compressed data with usual zlib headers.
     * @param data data to unpack
     * @return unpacked data
     * @throws IOException
     */
- (NSData *)KSProcess_zlib;
#endif

@end

@interface NSNumber (KSNumberPrivateMethods)

/**
 * Converts self (NSNumber) in to a Kaitai Struct Objective C enum.
 * @param dictionary contains the complete enum definition
 * @return Kaitai Struct Objective C enum
 */
- (NSDictionary *)KSENUMWithDictionary:(NSDictionary *)dictionary;

@end

@interface NSDictionary (KSDictionaryENUMPrivateMethods)

/**
 * Compares the two keys in a Kaitai Struct Objective C enum to see
 * if they are equal.
 * @param compare contains enum to compare against.
 * @return YES or NO
 */
- (BOOL) KSIsEqualToENUM:(NSDictionary *)compare;

@end

#endif
