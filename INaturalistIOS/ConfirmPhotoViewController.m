//
//  ConfirmPhotoViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <FontAwesomeKit/FAKFontAwesome.h>

#import "ConfirmPhotoViewController.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "MultiImageView.h"
#import "ObservationDetailViewController.h"
#import "TaxaSearchViewController.h"
#import "UIColor+ExploreColors.h"
#import "CategorizeViewController.h"

#define CHICLETWIDTH 100.0f
#define CHICLETHEIGHT 98.0f
#define CHICLETPADDING 2.0

@interface ConfirmPhotoViewController () <ObservationDetailViewControllerDelegate, TaxaSearchViewControllerDelegate> {
    MultiImageView *multiImageView;
}
@end

@implementation ConfirmPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    multiImageView = ({
        MultiImageView *iv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.borderColor = [UIColor blackColor];
        
        iv;
    });
    [self.view addSubview:multiImageView];
    
    UIButton *retake = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        button.backgroundColor = [UIColor blackColor];
        button.layer.borderColor = [UIColor grayColor].CGColor;
        button.layer.borderWidth = 1.0f;
        
        [button setTitle:NSLocalizedString(@"Retake", @"Retake a photo")
                forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [button bk_addEventHandler:^(id sender) {
            [self.navigationController popViewControllerAnimated:YES];
            if (self.assets)
                [self.navigationController setNavigationBarHidden:NO];
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:retake];

    UIButton *confirm = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        button.backgroundColor = [UIColor blackColor];
        
        button.layer.borderColor = [UIColor grayColor].CGColor;
        button.layer.borderWidth = 1.0f;
        
        [button setTitle:NSLocalizedString(@"Confirm", @"Confirm a new photo")
                forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [button bk_addEventHandler:^(id sender) {

            
            CategorizeViewController *categorize = [[CategorizeViewController alloc] initWithNibName:nil bundle:nil];

            if (self.image) {
                
                [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving...", @"Message when we're saving your photo.")
                                     maskType:SVProgressHUDMaskTypeGradient];

                // save image to assets library
                
                // embed geo
                CLLocationManager *loc = [[CLLocationManager alloc] init];
                NSMutableDictionary *mutableMetadata = [self.metadata mutableCopy];
                if (loc.location) {
                    
                    double latitude = fabs(loc.location.coordinate.latitude);
                    double longitude = fabs(loc.location.coordinate.longitude);
                    NSString *latitudeRef = loc.location.coordinate.latitude > 0 ? @"N" : @"S";
                    NSString *longitudeRef = loc.location.coordinate.longitude > 0 ? @"E" : @"W";
                    
                    NSDictionary *gps = @{ @"Latitude": @(latitude), @"Longitude": @(longitude),
                                           @"LatitudeRef": latitudeRef, @"LongitudeRef": longitudeRef };
                    
                    mutableMetadata[@"{GPS}"] = gps;
                }
                
                ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
                [lib writeImageToSavedPhotosAlbum:self.image.CGImage
                                         metadata:mutableMetadata
                                  completionBlock:^(NSURL *newAssetUrl, NSError *error) {
                                      if (error) {
                                          [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                          NSLog(@"ERROR: %@", error.localizedDescription);
                                      } else {
                                          [SVProgressHUD showSuccessWithStatus:nil];

                                          categorize.assetURL = newAssetUrl;
                                          categorize.shouldContinueUpdatingLocation = YES;
                                          [self.navigationController pushViewController:categorize
                                                                               animated:NO];
                                      }
                                  }];
                
            } else {
                // from photo library
                categorize.assets = self.assets;
                categorize.shouldContinueUpdatingLocation = NO;
                [UIView animateWithDuration:0.1f
                                 animations:^{
                                     button.center = CGPointMake(button.center.x,
                                                                 self.view.bounds.size.height + (button.frame.size.height / 2));
                                     retake.center = CGPointMake(button.center.x,
                                                                 self.view.bounds.size.height + (button.frame.size.height / 2));
                                     multiImageView.frame = self.view.bounds;
                                 } completion:^(BOOL finished) {
                                     [self.navigationController pushViewController:categorize
                                                                          animated:NO];
                                     
                                     button.center = CGPointMake(button.center.x,
                                                                 self.view.bounds.size.height - (button.frame.size.height / 2));
                                     retake.center = CGPointMake(button.center.x,
                                                                 self.view.bounds.size.height - (button.frame.size.height / 2));

                                 }];
                                 
            }
        } forControlEvents:UIControlEventTouchUpInside];

        button;
    });
    [self.view addSubview:confirm];
    
    NSDictionary *views = @{
                            @"image": multiImageView,
                            @"confirm": confirm,
                            @"retake": retake,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[image]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[retake]-0-[confirm(==retake)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[image]-0-[confirm(==60)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[image]-0-[retake(==60)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
}


- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    if (self.image) {
        multiImageView.images = @[ self.image ];
    } else if (self.assets && self.assets.count > 0) {
        NSArray *images = [self.assets bk_map:^id(ALAsset *asset) {
            return [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
        }];
        multiImageView.images = images;
        multiImageView.hidden = NO;
    }
}

@end
