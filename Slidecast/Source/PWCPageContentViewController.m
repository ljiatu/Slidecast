//
//  PWCPageContentViewController.m
//  Slidecast
//
//  Created by Jiatu Liu on 4/7/14.
//  Copyright (c) 2014 Purple Works. All rights reserved.
//

#import "PWCPageContentViewController.h"

#import "PWCConstants.h"

@interface PWCPageContentViewController ()

@end

@implementation PWCPageContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissKeyboard
{
    if ([self.textView isFirstResponder]) {
        // dismiss the keyboard when hitting save
        [self.textView resignFirstResponder];
    }
}

@end
