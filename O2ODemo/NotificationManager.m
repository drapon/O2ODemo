/*
 Copyright 2014 NIFTY Corporation All Rights Reserved.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "NotificationManager.h"

@interface NotificationManager()

//CLLocationManagerクラスのプロパティを作成
@property (nonatomic, strong) CLLocationManager *mLocationManager;
//CLLocationManagerは位置情報を扱うプロパティ

@end

@implementation NotificationManager

-(instancetype)init{
    
    //CLLocationManagerのインスタンスを作成
    self = [super init];
    self.mLocationManager = [[CLLocationManager alloc] init];
    self.mLocationManager.delegate = self;
    
    //位置情報を使用する許可画面を表示
    [self.mLocationManager requestWhenInUseAuthorization];
    
    return self;
}

- (void)searchLocations:(NSString*)locationId block:(void (^)(NSError *error))blk{
    
    //LocationクラスのNCMBObjectを作成
    NCMBObject *location = [NCMBObject objectWithClassName:@"Location"];

    //店舗情報のIDを設定
    location.objectId = locationId;

    //設定されたIDをもとにクラウドからデータを取得
    [location fetchInBackgroundWithBlock:^(NSError *localError) {
        if (localError){
            blk(localError);
        } else {
            //Locationクラスのgeoキーに設定されている位置情報を取得
            NCMBGeoPoint *point = [location objectForKey:@"geo"];
            [self updateLocation:point block:^(NSError *error) {
                if (error){
                    blk(error);
                } else {
                    blk(nil);
                }
            }];
        }
    }];

}

- (void)updateLocation:(NCMBGeoPoint*)geoPoint block:(void (^)(NSError *error))blk{
    
    //以前に登録されたNotificationをキャンセル
    [[UIApplication sharedApplication] cancelAllLocalNotifications];

    //再設定用のNotificationを作成
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
        return;
    localNotif.alertBody = [NSString stringWithFormat:@"近くでセール開催中！"];
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = 1;

    //CLCircularRegionの変数を用意
    CLCircularRegion *region = nil;
    
    //regionに設定するCLLocationCoordinate2Dを作成
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(geoPoint.latitude,
                                                                 geoPoint.longitude);

    //CLLocationCoordinate2Dが有効な値かを確認
    if (CLLocationCoordinate2DIsValid(location)){
        
        //リージョン作成(中心点、そこからの半径、regionの識別子を設定)
        region = [[CLCircularRegion alloc] initWithCenter:location
                                                   radius:50.0
                                               identifier:@"salePoint"];
        
        //リージョンから外に出た場合には通知が行われないようにNOを設定
        region.notifyOnExit = NO;
        
        //リージョンを設定してLocation Notificationを登録
        localNotif.region = region;
        localNotif.regionTriggersOnce = YES;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
        
        //コールバックを実行
        blk(nil);
    } else {
        NSDictionary *info = @{NSLocalizedDescriptionKey:@"Invalid coordinate info."};
        NSError *error = [NSError errorWithDomain:@"InvalidCLLocationError"
                                             code:1999
                                         userInfo:info];
        //コールバックを実行
        blk(error);
    }
}

@end
