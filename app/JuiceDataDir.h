#import <Foundation/Foundation.h>

static NSString *JuiceDataDirectory(void)
{
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        path = [dirs.firstObject stringByAppendingPathComponent:@"JuiceData"];
        [NSFileManager.defaultManager createDirectoryAtPath:path
            withIntermediateDirectories:YES attributes:nil error:nil];
    });
    return path;
}
