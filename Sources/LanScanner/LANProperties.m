//
//  LANProperties.m
//
//  Created by Michalis Mavris on 05/08/16.
//  Copyright © 2016 Miksoft. All rights reserved.
//

#import <SystemConfiguration/CaptiveNetwork.h>
#import "NetworkCalculator.h"
#import "LANProperties.h"
#import "MMDevice.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#include <netdb.h>

#include "if_arp.h"
#include "if_ether.h"
#include "route.h"

#import <SystemConfiguration/CaptiveNetwork.h>

#define VENDORS_DICTIONARY @"vendors.out"

#ifndef DEFAULT_WIFI_INTERFACE
#define DEFAULT_WIFI_INTERFACE @"en0"
#endif
#ifndef DEFAULT_CELLULAR_INTERFACE
#define DEFAULT_CELLULAR_INTERFACE @"pdp_ip0"
#endif

#ifndef deb
#define deb(format, ...) {if(DEBUG){NSString *__oo = [NSString stringWithFormat: @"%s:%@", __PRETTY_FUNCTION__, [NSString stringWithFormat:format, ## __VA_ARGS__]]; NSLog(@"%@", __oo); }}
#endif

#define BUFLEN (sizeof(struct rt_msghdr) + 512)
#define SEQ 9999
#define RTM_VERSION    5
#define RTM_GET    0x4
#define RTF_LLINFO    0x400
#define RTF_IFSCOPE 0x1000000
#define RTA_DST    0x1
#define CTL_NET    4

#if defined(BSD) || defined(__APPLE__)
#define ROUNDUP(a) ((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))
#endif

@implementation LANProperties

#pragma mark - Public methods


-(NSString*) getRouterIP {
    struct in_addr gatewayaddr;
    int r = [self getDefaultGateway:(&(gatewayaddr.s_addr))];
    if (r >= 0) {
        return [NSString stringWithUTF8String:inet_ntoa(gatewayaddr)];
    }
    return @"";
}

-(int) getDefaultGateway: (in_addr_t *) addr  {
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET,
        NET_RT_FLAGS, RTF_GATEWAY};
    size_t l;
    char * buf, * p;
    struct rt_msghdr * rt;
    struct sockaddr * sa;
    struct sockaddr * sa_tab[RTAX_MAX];
    int i;
    int r = -1;
    if(sysctl(mib, sizeof(mib)/sizeof(int), 0, &l, 0, 0) < 0) {
        return -1;
    }
    if(l > 0) {
        buf = malloc(l);
        if(sysctl(mib, sizeof(mib)/sizeof(int), buf, &l, 0, 0) < 0) {
            return -1;
        }
        for(p = buf; p < buf + l; p += rt->rtm_msglen) {
            rt = (struct rt_msghdr *)p;
            sa = (struct sockaddr *)(rt + 1);
            for(i = 0; i < RTAX_MAX; i++) {
                if(rt->rtm_addrs & (1 << i)) {
                    sa_tab[i] = sa;
                    sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
                } else {
                    sa_tab[i] = NULL;
                }
            }
            
            if( ((rt->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
               && sa_tab[RTAX_DST]->sa_family == AF_INET
               && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET) {
                
                if(((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0) {
                    char ifName[128];
                    if_indextoname(rt->rtm_index,ifName);
                    
                    if(strcmp([DEFAULT_WIFI_INTERFACE UTF8String], ifName) == 0){
                        
                        *addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
                        r = 0;
                    }
                }
            }
        }
        free(buf);
    }
    return r;
}


+(MMDevice*)localIPAddress {
    
    MMDevice *localDevice = [[MMDevice alloc]init];
    
    localDevice.ipAddress = @"error";
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    
    if (success == 0) {
        
        temp_addr = interfaces;
        
        while(temp_addr != NULL) {
            
            // check if interface is en0 which is the wifi connection on the iPhone
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    
                    localDevice.ipAddress = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    localDevice.subnetMask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                    localDevice.hostname = [self getHostFromIPAddress:localDevice.ipAddress];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    //In case we failed to fetch IP address
    if ([localDevice.ipAddress isEqualToString:@"error"]) {
        return nil;
    }
    
    //Mark the device as the local IP
    localDevice.isLocalDevice = YES;

    return localDevice;
}

+(NSString*)fetchSSIDInfo {
    
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();

    NSDictionary *info;
    
    for (NSString *ifnam in ifs) {
        
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        
        if (info && [info count]) {
    
            return [info objectForKey:@"SSID"];
            break;
        }
    }
    
    return @"No WiFi Available";
}
//Getting all the hosts to ping and returns them as array
+(NSArray*)getAllHostsForIP:(NSString*)ipAddress andSubnet:(NSString*)subnetMask {
    
    return [NetworkCalculator getAllHostsForIP:ipAddress andSubnet:subnetMask];
}

//Not working
#pragma mark - Get Host from IP
+(NSString *)getHostFromIPAddress:(NSString*)ipAddress {
    struct addrinfo *result = NULL;
    struct addrinfo hints;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags = AI_NUMERICHOST;
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = 0;
    
    int errorStatus = getaddrinfo([ipAddress cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
    if (errorStatus != 0) {
        return nil;
    }
    
    CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
    if (addressRef == nil) {
        return nil;
    }
    freeaddrinfo(result);
    
    CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
    if (hostRef == nil) {
        return nil;
    }
    CFRelease(addressRef);
    
    BOOL succeeded = CFHostStartInfoResolution(hostRef, kCFHostNames, NULL);
    if (!succeeded) {
        return nil;
    }
    
    NSMutableArray *hostnames = [NSMutableArray array];
    
    CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
    for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)hostnamesRef count]; currentIndex++) {
        [hostnames addObject:[(__bridge NSArray *)hostnamesRef objectAtIndex:currentIndex]];
    }
    
    return hostnames[0];
}

@end
