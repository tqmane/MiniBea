#import "BeaUploadTask.h"

@interface BeaUploadTask ()
@property (nonatomic, strong) UIImage *rawFrontImage;
@property (nonatomic, strong) UIImage *rawBackImage;
@end

@implementation BeaUploadTask
NSData* compressImage(UIImage *image, NSUInteger targetDataSize) {
    if (!image) return nil;
    CGFloat compressionFactor = 1.0;
    NSData *imageData = UIImageJPEGRepresentation(image, compressionFactor);

    // if the current data length is below the target's size return the image
    if (imageData.length < targetDataSize) {
        return imageData;
    }
    
    while (imageData.length > targetDataSize && compressionFactor > 0.1) {
        compressionFactor -= 0.1;
        imageData = UIImageJPEGRepresentation(image, compressionFactor);
    }
    
    return imageData;
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    CGFloat aspectRatio = image.size.width / image.size.height;
    CGFloat targetRatio = size.width / size.height;
    CGFloat deviation = fabs(aspectRatio - targetRatio);

    if (deviation > 0.1) {
        size = CGSizeMake(size.width, size.width / aspectRatio);
    }

    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (instancetype)initWithData:(NSDictionary *)data frontImage:(UIImage *)frontImage backImage:(UIImage *)backImage {
    self = [super init];
    if (self) {
        self.userDictionary = data;

        self.headers = [[BeaTokenManager sharedInstance] headers];
        
        // Store raw images for async processing later
        self.rawFrontImage = frontImage;
        self.rawBackImage = backImage;
    }
    return self;
}

- (void)handleErrorWithTitle:(NSString *)title message:(NSString *)message completion:(void (^)(BOOL success, NSError *error))completion {
    NSError *error = [NSError errorWithDomain:@"com.yan.bea" code:0 userInfo:@{ @"title":title, @"description":message }];
    completion(NO, error);
}

- (void)uploadBeRealWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    // Perform compression asynchronously to avoid blocking the main thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *resizedFrontImage = [self resizeImage:self.rawFrontImage toSize:CGSizeMake(1500, 2000)];
        UIImage *resizedBackImage = [self resizeImage:self.rawBackImage toSize:CGSizeMake(1500, 2000)];

        self.frontImageData = compressImage(resizedFrontImage, 1048576);
        self.backImageData = compressImage(resizedBackImage, 1048576);
        
        // Once compressed, proceed with the upload logic
        [self getRegion];

        // BeReal 4.58.0 uses a new endpoint for multi-format uploads
        // Try new endpoint first, fallback to legacy endpoint if needed
        NSURL *uploadRequestURL = [NSURL URLWithString:@"https://mobile-l7.bereal.com/api/content/posts/multi-format-upload-url?mimeType=image/webp"];
        NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:uploadRequestURL];
        [uploadRequest setHTTPMethod:@"GET"];
        
        // Add updated headers for BeReal 4.58.0
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
            [uploadRequest setValue:value forHTTPHeaderField:field];
        }];
        
        // Add additional headers that may be required in newer versions
        dispatch_async(dispatch_get_main_queue(), ^{
             // System version access theoretically should be main thread? 
             // UIDevice properties are usually thread-safe but let's be safe if we access specific things.
             // Actually, UIDevice currentDevice is thread safe.
             // But we are constructing the request.
             // We can continue on background thread.
        });
             
        NSString *osVersion = [[UIDevice currentDevice] systemVersion];
        [uploadRequest setValue:@"4.58.0-(458000)" forHTTPHeaderField:@"bereal-app-version"];
        [uploadRequest setValue:osVersion forHTTPHeaderField:@"bereal-os-version"];
        [uploadRequest setValue:[[NSTimeZone localTimeZone] name] forHTTPHeaderField:@"bereal-timezone"];

        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadRequestTask = [session dataTaskWithRequest:uploadRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *getError) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSDictionary *uploadRequestResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            // If new endpoint fails, try legacy endpoint
            if (httpResponse.statusCode == 404 || uploadRequestResponse[@"error"] || getError) {
                [self tryLegacyUploadWithCompletion:completion];
            } else {
                [self makePUTRequestWithData:uploadRequestResponse completion:completion];
            } 
        }];

        [uploadRequestTask resume];
    });
}

// Fallback to legacy upload-url endpoint for older API versions
- (void)tryLegacyUploadWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    NSURL *uploadRequestURL = [NSURL URLWithString:@"https://mobile-l7.bereal.com/api/content/posts/upload-url?mimeType=image/webp"];
    NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:uploadRequestURL];
    [uploadRequest setHTTPMethod:@"GET"];

    [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        [uploadRequest setValue:value forHTTPHeaderField:field];
    }];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadRequestTask = [session dataTaskWithRequest:uploadRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *getError) {
        NSDictionary *uploadRequestResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (uploadRequestResponse[@"error"] || getError) {
            [self handleErrorWithTitle:@"Something went wrong..." message:@"0 - Bea could not initiate the upload process" completion:completion];
        } else {
            [self makePUTRequestWithData:uploadRequestResponse completion:completion];
        } 
    }];

    [uploadRequestTask resume];
}

- (void)makePUTRequestWithData:(NSDictionary *)response completion:(void (^)(BOOL success, NSError *error))completion {
    if (!response) return;

    NSString *frontCameraURLString = response[@"data"][0][@"url"];
    NSString *backCameraURLString = response[@"data"][1][@"url"];

    NSURL *frontCameraURL = [NSURL URLWithString:frontCameraURLString];
    NSURL *backCameraURL = [NSURL URLWithString:backCameraURLString];
    
    // those headers have to be included in the next put request 
    NSDictionary *frontHeaders = response[@"data"][0][@"headers"];
    NSDictionary *backHeaders = response[@"data"][1][@"headers"];

    NSString *frontImageUploadPath = response[@"data"][0][@"path"];
    NSString *backImageUploadPath = response[@"data"][1][@"path"];

    NSString *frontImageBucket = response[@"data"][0][@"bucket"];
    NSString *backImageBucket = response[@"data"][1][@"bucket"];
    
    // otherwise the postbereal function would get called even if one of the put requests didnt succeed
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self putPhotoWithURL:frontCameraURL headers:frontHeaders imageData:self.frontImageData completion:^(BOOL success) {
        if (!success) {
            return;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [self putPhotoWithURL:backCameraURL headers:backHeaders imageData:self.backImageData completion:^(BOOL success) {
        if (!success) {
            return;
        }
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self postBeRealWithFrontPath:frontImageUploadPath backPath:backImageUploadPath frontBucket:frontImageBucket backBucket:backImageBucket completion:completion];
    });
}

- (void)putPhotoWithURL:(NSURL *)url headers:(NSDictionary *)headers imageData:(NSData *)imageData completion:(void (^)(BOOL success))completion {

    NSMutableURLRequest *putRequest = [NSMutableURLRequest requestWithURL:url];
    [putRequest setHTTPMethod:@"PUT"];
    [putRequest setAllHTTPHeaderFields:headers];

    NSURLSessionTask *task = [[NSURLSession sharedSession] uploadTaskWithRequest:putRequest fromData:imageData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || httpResponse.statusCode > 299) {
            completion(NO);
            return;
        }

        if (data) {
            completion(YES);
        }
    }];
    
    [task resume];
}

- (void)postBeRealWithFrontPath:(NSString *)frontPath backPath:(NSString *)backPath frontBucket:(NSString *)frontBucket backBucket:(NSString *)backBucket completion:(void (^)(BOOL success, NSError *error))completion {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSXXX"];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];

    if (![self.userDictionary[@"isLate"] boolValue] && self.lastMoment) {
        // randomize the taken at to be between the startDate and endDate because its
        // logically impossible to "post" on the start time
        NSDate *moment = [dateFormatter dateFromString:self.lastMoment];
        NSInteger randomSeconds = arc4random_uniform(105 - 60) + 60;
        NSDate *dateInRange = [moment dateByAddingTimeInterval:randomSeconds];
        NSString *dateString = [dateFormatter stringFromDate:dateInRange];
        self.takenAt = dateString;
    } else {
        NSDate *currentDate = [NSDate date];
        self.takenAt = [dateFormatter stringFromDate:currentDate];
    }
    
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:@{
        @"visibility": @[@"friends"],
        @"isLate": @([self.userDictionary[@"isLate"] boolValue]),
        @"retakeCounter": self.userDictionary[@"retakeCounter"] ?: @0,
        @"takenAt": self.takenAt,
        @"backCamera": @{
            @"bucket": backBucket,
            @"height": @2000,
            @"width": @1500,
            @"path": backPath
        },
        @"frontCamera": @{
            @"bucket": frontBucket,
            @"height": @2000,
            @"width": @1500,
            @"path": frontPath
        }
    }];

    if (self.userDictionary[@"music"]) {
        [payload setObject:self.userDictionary[@"music"] forKey:@"music"];
    }

    if (self.userDictionary[@"longitude"] && self.userDictionary[@"latitude"]) {
        NSDictionary *locationDict = @{
            @"latitude": self.userDictionary[@"latitude"],
            @"longitude": self.userDictionary[@"longitude"]
        };
        [payload setObject:locationDict forKey:@"location"];
    }

    if (self.userDictionary[@"caption"]) {
        [payload setObject:self.userDictionary[@"caption"] forKey:@"caption"];
    }

    NSData *payloadJSON = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingWithoutEscapingSlashes error:nil];

    NSURL *postBeRealURL = [NSURL URLWithString:@"https://mobile-l7.bereal.com/api/content/posts"];
    NSMutableURLRequest *postBeRealRequest = [NSMutableURLRequest requestWithURL:postBeRealURL];

    [postBeRealRequest setHTTPMethod:@"POST"];

    [postBeRealRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        [postBeRealRequest setValue:value forHTTPHeaderField:field];
    }];

    NSURLSessionUploadTask *uploadTask = [[NSURLSession sharedSession] uploadTaskWithRequest:postBeRealRequest fromData:payloadJSON completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || httpResponse.statusCode > 299) {
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            //NSString *message = [NSString stringWithFormat:@"1 - Uploading failed: %@: %@", responseDictionary[@"statusCode"], responseDictionary[@"errorKey"]];
            NSString *message = [NSString stringWithFormat:@"%@, %@, %@", responseDictionary[@"error"], responseDictionary[@"message"], responseDictionary[@"errorKey"]];
            [self handleErrorWithTitle:@"API Error" message:message completion:completion];
            return;
        }
        
        if (data) {
            // the upload succeded
            completion(YES, nil);
        }
    }];

    [uploadTask resume];
}

- (void)getRegion {
    NSURL *meURL = [NSURL URLWithString:@"https://mobile-l7.bereal.com/api/person/me"];

    NSMutableURLRequest *regionRequest = [NSMutableURLRequest requestWithURL:meURL];
    
    [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        [regionRequest setValue:value forHTTPHeaderField:field];
    }];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *regionRequestTask = [session dataTaskWithRequest:regionRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || httpResponse.statusCode != 200) {
            return;
        } else {
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            self.region = response[@"region"];
            [self getLastMoment];
        }    
    }];

    [regionRequestTask resume];
}

- (void)getLastMoment {
    NSURL *lastMomentURL = [NSURL URLWithString:@"https://mobile-l7.bereal.com/api/bereal/moments/last/"];
    lastMomentURL = [lastMomentURL URLByAppendingPathComponent:self.region];

    NSMutableURLRequest *lastMomentRequest = [NSMutableURLRequest requestWithURL:lastMomentURL];
    [lastMomentRequest setHTTPMethod:@"GET"];

    [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        [lastMomentRequest setValue:value forHTTPHeaderField:field];
    }];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *lastMomentRequestTask = [session dataTaskWithRequest:lastMomentRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || httpResponse.statusCode != 200) {
            return;
        } else {
            NSDictionary *lastMomentResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            self.lastMoment = lastMomentResponse[@"startDate"];
        }    
    }];

    [lastMomentRequestTask resume];
}
@end