#import "IntercomFlutterPlugin.h"
#import "Intercom.h"
#import <UserNotifications/UserNotifications.h>


typedef void(^DeviceTokenBlock)(NSData *);

@implementation IntercomFlutterPlugin {
    NSData *_deviceToken;
    DeviceTokenBlock _deviceTokenBlock;
}


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    IntercomFlutterPlugin* instance = [[IntercomFlutterPlugin alloc] init];
    FlutterMethodChannel* channel =
    [FlutterMethodChannel methodChannelWithName:@"maido.io/intercom"
                                binaryMessenger:[registrar messenger]];
    [registrar addApplicationDelegate: instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
    if([@"initialize" isEqualToString:call.method]) {
        NSString *iosApiKey = call.arguments[@"iosApiKey"];
        NSString *appId = call.arguments[@"appId"];
        [Intercom setApiKey:iosApiKey forAppId:appId];
        result(@"Initialized Intercom");
    }
    else if([@"registerUnidentifiedUser" isEqualToString:call.method]) {
        [Intercom registerUnidentifiedUser];
        result(@"Registered unidentified user");
    }
    else if([@"setUserHash" isEqualToString:call.method]) {
        NSString *userHash = call.arguments[@"userHash"];
        [Intercom setUserHash:userHash];
        result(@"User hash added");
    }
    else if([@"registerIdentifiedUser" isEqualToString:call.method]) {
        NSString *userId = call.arguments[@"userId"];
        NSString *email = call.arguments[@"email"];
        if(userId != (id)[NSNull null] || email != (id)[NSNull null]) {
            if(userId == (id)[NSNull null]) {
                [Intercom registerUserWithEmail:email];
            } else if(email == (id)[NSNull null]) {
                [Intercom registerUserWithUserId:userId];
            } else {
                [Intercom registerUserWithUserId:userId email:email];
            }
            result(@"Registered user");
        }
    }
    else if([@"setDeviceToken" isEqualToString:call.method]) {
        FlutterStandardTypedData* deviceTokenData = call.arguments[@"deviceToken"];
        NSData *deviceToken = deviceTokenData.data;
        [Intercom setDeviceToken: deviceToken];
        result(@"Setting device token");
    }
    else if([@"getDeviceToken" isEqualToString:call.method]) {
        if (_deviceToken) {
            result(_deviceToken);
        } else {
            _deviceTokenBlock = ^void(NSData *deviceToken) {
                result(deviceToken);
            };
        }
    }
    else if([@"requestNotificationsPermission" isEqualToString:call.method]) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        UNAuthorizationOptions options = 0;
        NSDictionary *arguments = call.arguments;
        if ([arguments[@"sound"] boolValue]) {
            options |= UIUserNotificationTypeSound;
        }
        if ([arguments[@"alert"] boolValue]) {
            options |= UIUserNotificationTypeAlert;
        }
        if ([arguments[@"badge"] boolValue]) {
            options |= UIUserNotificationTypeBadge;
        }
        [center requestAuthorizationWithOptions: options completionHandler:^(BOOL granted, NSError * _Nullable error){
            if (!error) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
                result(@"Requested notifications permission");
            }
        }];
    }
    else if([@"setLauncherVisibility" isEqualToString:call.method]) {
        NSString *visibility = call.arguments[@"visibility"];
        [Intercom setLauncherVisible:[@"VISIBLE" isEqualToString:visibility]];
        result(@"Setting launcher visibility");
    }
    else if([@"setInAppMessagesVisibility" isEqualToString:call.method]) {
        NSString *visibility = call.arguments[@"visibility"];
        [Intercom setInAppMessagesVisible:[@"VISIBLE" isEqualToString:visibility]];
        result(@"Setting in app messages visibility");
    }
    else if([@"unreadConversationCount" isEqualToString:call.method]) {
        NSUInteger count = [Intercom unreadConversationCount];
        result(@(count));
    }
    else if([@"displayMessenger" isEqualToString:call.method]) {
        [Intercom presentMessenger];
        result(@"Presented messenger");
    }
    else if([@"displayHelpCenter" isEqualToString:call.method]) {
        [Intercom presentHelpCenter];
        result(@"Presented help center");
    }
    else if([@"updateUser" isEqualToString:call.method]) {
        ICMUserAttributes *attributes = [ICMUserAttributes new];
        NSString *email = call.arguments[@"email"];
        if(email != (id)[NSNull null]) {
            attributes.email = email;
        }
        NSString *name = call.arguments[@"name"];
        if(name != (id)[NSNull null]) {
            attributes.name = name;
        }
        NSString *phone = call.arguments[@"phone"];
        if(phone != (id)[NSNull null]) {
            attributes.phone = phone;
        }
        NSString *userId = call.arguments[@"userId"];
        if(userId != (id)[NSNull null]) {
            attributes.userId = userId;
        }
        NSString *companyName = call.arguments[@"company"];
        NSString *companyId = call.arguments[@"companyId"];
        if(companyName != (id)[NSNull null] && companyId != (id)[NSNull null]) {
            ICMCompany *company = [ICMCompany new];
            company.name = companyName;
            company.companyId = companyId;
            attributes.companies = @[company];
        }
        NSDictionary *customAttributes = call.arguments[@"customAttributes"];
        if(customAttributes != (id)[NSNull null]) {
            attributes.customAttributes = customAttributes;
        }
        [Intercom updateUser:attributes];
        result(@"Updated user");
    }
    else if([@"logout" isEqualToString:call.method]) {
        [Intercom logout];
        result(@"Logged out");
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    _deviceToken = deviceToken;
    if (_deviceTokenBlock) {
        _deviceTokenBlock(deviceToken);
    }
}

@end
