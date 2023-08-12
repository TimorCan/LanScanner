//
//  MMDevice.h
//  MMLanScanDemo
//
//  Created by Michalis Mavris on 08/07/2017.
//  Copyright © 2017 Miksoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMDevice : NSObject

@property (nonatomic,strong,nullable) NSString *hostname;
@property (nonatomic,strong,nullable) NSString *ipAddress;
@property (nonatomic,strong,nullable) NSString *macAddress;
@property (nonatomic,strong,nullable) NSString *subnetMask;
@property (nonatomic,strong,nullable) NSString *brand;
@property (nonatomic,assign) BOOL isLocalDevice;
-( NSString* _Nonnull )macAddressLabel;
@end
