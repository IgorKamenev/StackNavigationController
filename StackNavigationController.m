//
//  StackNavigationController.m
//  StackNavigationController
//
//  Created by Igor Kamenev on 25.12.14.
//  Copyright (c) 2014 Igor Kamenev. All rights reserved.
//


#import "StackNavigationController.h"

@interface StackNavigationController () <UINavigationControllerDelegate>

@property (nonatomic, assign) BOOL isTransitioning;
@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, weak) id<UINavigationControllerDelegate> customDelegate;

@end

@implementation StackNavigationController

-(void)viewDidLoad {
    [super viewDidLoad];

    if (self.delegate) {
        self.customDelegate = self.delegate;
    }
    self.delegate = self;
    
    self.tasks = [NSMutableArray new];
}

// we should save navController.delegate to another property because we need delegate
// to prevent multiple push/pop bug
-(void)setDelegate:(id<UINavigationControllerDelegate>)delegate
{
    if (delegate == self) {
        [super setDelegate:delegate];
    } else {
        self.customDelegate = delegate;
    }
}


- (void) pushViewController:(UIViewController *)viewController animated:(BOOL)animated {

    @synchronized(self.tasks) {
        if (self.isTransitioning) {
            
            void (^task)(void) = ^{
                [self pushViewController:viewController animated:animated];
            };
            
            [self.tasks addObject:task];
        }
        else {
            self.isTransitioning = YES;
            [super pushViewController:viewController animated:animated];
        }
    }
}

-(UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    @synchronized(self.tasks) {
        if (self.isTransitioning) {
            
            void (^task)(void) = ^{
                [self popViewControllerAnimated:animated];
            };
            
            [self.tasks addObject:task];
      
            return nil;
            
        } else {
            
            self.isTransitioning = YES;
            return [super popViewControllerAnimated:animated];
            
        }
    }
}

-(NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    @synchronized(self.tasks) {
        if (self.isTransitioning) {
            
            void (^task)(void) = ^{
                [self popToViewController:viewController animated:animated];
            };
            
            [self.tasks addObject:task];
            
            return nil;
            
        } else {
            self.isTransitioning = YES;
            return [super popToViewController:viewController animated:animated];
        }
    }
}

-(NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    @synchronized(self.tasks) {
        if (self.isTransitioning) {
            
            void (^task)(void) = ^{
                [self popToRootViewControllerAnimated:animated];
            };
            
            [self.tasks addObject:task];
            
            return nil;
            
        } else {
            self.isTransitioning = YES;
            return [super popToRootViewControllerAnimated:animated];
        }
    }
}

- (void) runNextTask {

    @synchronized(self.tasks) {
        if (self.tasks.count) {
            void (^task)(void) = self.tasks[0];
            [self.tasks removeObjectAtIndex:0];
            task();
        }
    }
}

#pragma mark UINavigationControllerDelegate

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.isTransitioning = NO;
    
    if (self.customDelegate) {
        [self.customDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
    
    // black magic :)
    // if one of push/pop will be without animation - we should place this code to the end of runLoop to prevent bad behavior
    [self performSelector:@selector(runNextTask) withObject:nil afterDelay:0.0f];
}


// forward other delegate method to customDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.customDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
}

- (NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
    return [self.customDelegate navigationControllerSupportedInterfaceOrientations:navigationController];
}

- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController
{
    return [self.customDelegate navigationControllerPreferredInterfaceOrientationForPresentation:navigationController];
}

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController
{
    return [self.customDelegate navigationController:navigationController interactionControllerForAnimationController:animationController];
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    return [self.customDelegate navigationController:navigationController
              animationControllerForOperation:operation
                           fromViewController:fromVC
                             toViewController:toVC];
}

@end
