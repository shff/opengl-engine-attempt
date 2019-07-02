#import <AudioToolbox/AudioToolbox.h>
#import <Cocoa/Cocoa.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <OpenGL/gl.h>

static OSStatus audioCallback(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber, UInt32 inNumberFrames,
                              AudioBufferList *ioData)
{
  static double theta = 0.0;
  const double amplitude = 0.25;
  const double theta_increment = 2.0 * M_PI * 440.0 / 41100.0;

  Float32 *buffer = (Float32 *)ioData->mBuffers[0].mData;
  for (UInt32 frame = 0; frame < inNumberFrames; frame++) 
  {
    buffer[frame] = 0; // sin(theta) * amplitude;

    theta += theta_increment;
    if (theta > 2.0 * M_PI)
    {
      theta -= 2.0 * M_PI;
    }
  }

  return 0;
}

int main(int argc, char **argv)
{
  @autoreleasepool
  {
    [NSApplication sharedApplication];

    // Get the Application Name
    id appName = [[NSProcessInfo processInfo] processName];

    // Prevent Sleeping
    IOPMAssertionID assertionID;
    IOPMAssertionCreateWithName(
        kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn,
        CFSTR("Application is an interactive game."), &assertionID);

    // Initialize Audio
    AudioComponentDescription desc = {
        .componentType = kAudioUnitType_Output,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
        .componentSubType = kAudioUnitSubType_DefaultOutput};
    AudioStreamBasicDescription audioFormat = {
        .mSampleRate = 44100.00,
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
        .mFramesPerPacket = 1,
        .mChannelsPerFrame = 1,
        .mBitsPerChannel = 32,
        .mBytesPerPacket = 4,
        .mBytesPerFrame = 4};
    AURenderCallbackStruct callback = {.inputProc = audioCallback};
    AudioUnit audioUnit;
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    AudioComponentInstanceNew(comp, &audioUnit);
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input, 0, &audioFormat,
                         sizeof(audioFormat));
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input, 0, &callback, sizeof(callback));
    AudioUnitInitialize(audioUnit);
    AudioOutputUnitStart(audioUnit);

    // Create the Window
    NSWindow *window = [[[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 640, 480)
                  styleMask:NSTitledWindowMask | NSResizableWindowMask |
                            NSClosableWindowMask | NSMiniaturizableWindowMask
                    backing:NSBackingStoreBuffered
                      defer:NO] autorelease];
    [window cascadeTopLeftFromPoint:NSMakePoint(20, 20)];
    [window setMinSize:NSMakeSize(300, 200)];
    [window makeKeyAndOrderFront:nil];
    [window setTitle:appName];
    [window center];

    // Create the Menus
    id menubar = [[NSMenu new] autorelease];
    id appMenu = [[NSMenu new] autorelease];
    id appMenuItem =
        [menubar addItemWithTitle:@"" action:NULL keyEquivalent:@""];
    [appMenuItem setSubmenu:appMenu];
    id servicesMenu = [[NSMenu alloc] autorelease];
    id windowMenuItem =
        [menubar addItemWithTitle:@"Window" action:NULL keyEquivalent:@""];
    id windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenuItem setSubmenu:windowMenu];
    id helpMenuItem =
        [menubar addItemWithTitle:@"Help" action:NULL keyEquivalent:@""];
    id helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpMenuItem setSubmenu:helpMenu];
    [[appMenu addItemWithTitle:@"Services" action:NULL keyEquivalent:@""]
        setSubmenu:servicesMenu];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Hide"
                       action:@selector(hide:)
                keyEquivalent:@"h"];
    [[appMenu addItemWithTitle:@"Hide Others"
                        action:@selector(hideOtherApplications:)
                 keyEquivalent:@"h"]
        setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
    [appMenu addItemWithTitle:@"Show All"
                       action:@selector(unhideAllApplications:)
                keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit"
                       action:@selector(terminate:)
                keyEquivalent:@"q"];
    [windowMenu addItemWithTitle:@"Minimize"
                          action:@selector(performMiniaturize:)
                   keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom"
                          action:@selector(performZoom:)
                   keyEquivalent:@"n"];
    [[windowMenu addItemWithTitle:@"Full Screen"
                           action:@selector(toggleFullScreen:)
                    keyEquivalent:@"f"]
        setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];
    [windowMenu addItemWithTitle:@"Close Window"
                          action:@selector(performClose:)
                   keyEquivalent:@"w"];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItemWithTitle:@"Bring All to Front"
                          action:@selector(arrangeInFront:)
                   keyEquivalent:@""];

    // Create the View
    id view = [[NSView new] autorelease];
    [window setContentView:view];
    [window makeFirstResponder:view];
    [window setAcceptsMouseMovedEvents:YES];

    // Create the Context
    GLint swapInterval = 1;
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFADoubleBuffer,  NSOpenGLPFADepthSize,          24,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, 0};
    id format =
        [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
    id context = [[[NSOpenGLContext alloc] initWithFormat:format
                                             shareContext:nil] autorelease];
    [context setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];
    [context setView:view];
    [context makeCurrentContext];

    // Setup observers
    __block int running = 1;
    [[NSNotificationCenter defaultCenter]
        addObserverForName:NSWindowWillCloseNotification
                    object:window
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                  running = 0;
                }];
    [[NSNotificationCenter defaultCenter]
        addObserverForName:NSViewGlobalFrameDidChangeNotification
                    object:view
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                  [context update];
                }];

    // Finish loading
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp setMainMenu:menubar];
    [NSApp setWindowsMenu:windowMenu];
    [NSApp setHelpMenu:helpMenu];
    [NSApp setServicesMenu:servicesMenu];
    [NSApp finishLaunching];

    // Game Loop
    while (running)
    {
      NSEvent *event;
      while ((event = [NSApp nextEventMatchingMask:NSAnyEventMask
                                         untilDate:[NSDate distantPast]
                                            inMode:NSDefaultRunLoopMode
                                           dequeue:YES]) != nil)
      {
        [NSApp sendEvent:event];
      }

      glViewport(0, 0, (int)[view frame].size.width,
                 (int)[view frame].size.height);
      glClearColor(0.2f, 0.2f, 0.2f, 0.0f);
      glClear(GL_COLOR_BUFFER_BIT);
      glFlush();

      [context flushBuffer];
    }

    AudioOutputUnitStop(audioUnit);
    AudioComponentInstanceDispose(audioUnit);
    IOPMAssertionRelease(assertionID);

    [NSApp terminate:nil];
  }
}
