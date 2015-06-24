//
//  Licensed under MIT
//  Copyright (c) 2015 Oguz Bastemur. All rights reserved.
//

#import "ViewController.h"
#import "JXcore.h"

static void callback(NSArray *args, NSString *return_id) { }

static bool initialized = false;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UITextView *txtStory;
@property (weak, nonatomic) IBOutlet UILabel *lblURL2;
@property (weak, nonatomic) IBOutlet UILabel *lblURL;
- (IBAction)btnUpdate:(id)sender;
@end

@implementation ViewController

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
   [self.view endEditing:YES];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  
  
  // do not initialize JXcore twice
  if (initialized) return;
  initialized = true;
  
  // makes JXcore instance running under it's own thread
  [JXcore useSubThreading];
  
  // start engine (main file will be JS/main.js. This is the initializer file)
  [JXcore startEngine:@"JS/main"];
  
  // Define ScreenBrightness method to JS side so we can call it from there (see app.js)
  [JXcore addNativeBlock:^(NSArray *params, NSString *callbackId) {
    CGFloat br = [[UIScreen mainScreen] brightness];
    
    [JXcore callEventCallback:callbackId withJSON:[NSString stringWithFormat:@"%f", (float)br]];
  } withName:@"ScreenBrightness"];
  
  
  // Second native method for JS side
  [JXcore addNativeBlock:^(NSArray *params, NSString *callbackId) {
    if (params == nil || [params count] == 0)
    {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No IPv4?"
                                            message:@"Better connect to Wifi to test this application"
                                           delegate:nil 
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
      [alert show];
      return;
    }
    
    NSString* ipaddress = [params objectAtIndex:0];
    NSString* ipaddress2 =  nil;
    
    if ([params count] > 1)
      ipaddress2 = [params objectAtIndex:1];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [[self lblURL] setText:[NSString stringWithFormat:@"http://%@:3000/", ipaddress]];
      
      if (ipaddress2 != nil)
        [[self lblURL2] setText:[NSString stringWithFormat:@"http://%@:3000/", ipaddress2]];
    });
  } withName:@"SetIPAddress"];
  
  
  // Start the application (app.js)
  NSArray *params = [NSArray arrayWithObjects:@"app.js", nil];
  [JXcore callEventCallback:@"StartApplication" withParams:params];
}

- (IBAction)btnUpdate:(id)sender {
  if (!initialized)
  {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wait for JXcore"
                                                message:@"JXcore is not ready"
                                               delegate:nil 
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
    [alert show];
  } else {
    NSArray *params = [NSArray arrayWithObjects:[_txtStory text], nil];
    [JXcore callEventCallback:@"UpdateHTML" withParams:params];
    [self.view endEditing:YES];
    [_lblTitle setText:@"HTML is updated!"];
    
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[self lblTitle] setText:@"Say Something!"];
    });
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}
@end
