import Cocoa
import GLKit
import IOKit.pwr_mgt

NSApplication.sharedApplication()

// Get the Application Name
var appName = NSProcessInfo.processInfo().processName

// Prevent Sleeping
var assertionID = IOPMAssertionID()
IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, UInt32(kIOPMAssertionLevelOn), "Application is an interactive game." as CFString, &assertionID)
IOPMAssertionRelease(assertionID)

// Create the Window
var window = NSWindow(contentRect: NSMakeRect(0, 0, 640, 480), styleMask: NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask, backing: .Buffered, defer: false)
window.cascadeTopLeftFromPoint(NSMakePoint(20, 20))
window.minSize = NSMakeSize(300, 200)
window.makeKeyAndOrderFront(nil)
window.title = appName
window.center()

// Create the Menus
var menubar = NSMenu()
var appMenu = NSMenu()
var appMenuItem = menubar.addItemWithTitle("", action: nil, keyEquivalent: "")
appMenuItem!.submenu = appMenu
var servicesMenu = NSMenu()
var windowMenuItem = menubar.addItemWithTitle("Window", action: nil, keyEquivalent: "")
var windowMenu = NSMenu(title: "Window")
windowMenuItem!.submenu = windowMenu
var helpMenuItem = menubar.addItemWithTitle("Help", action: nil, keyEquivalent: "")
var helpMenu = NSMenu(title: "Help")
helpMenuItem!.submenu = helpMenu
appMenu.addItemWithTitle("Services", action: nil, keyEquivalent: "")!.submenu = servicesMenu
appMenu.addItem(NSMenuItem.separatorItem())
appMenu.addItemWithTitle("Hide", action: #selector(NSApplication.hide), keyEquivalent: "h")
appMenu.addItemWithTitle("Hide Others", action: #selector(NSApplication.hideOtherApplications), keyEquivalent: "h") //!.keyEquivalentModifierMask = .AlternateKey | .CommandKey
appMenu.addItemWithTitle("Show All", action: #selector(NSApplication.unhideAllApplications), keyEquivalent: "")
appMenu.addItem(NSMenuItem.separatorItem())
appMenu.addItemWithTitle("Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
windowMenu.addItemWithTitle("Minimize", action: #selector(window.performMiniaturize), keyEquivalent: "m")
windowMenu.addItemWithTitle("Zoom", action: #selector(window.performZoom), keyEquivalent: "n")
windowMenu.addItemWithTitle("Full Screen", action: #selector(window.toggleFullScreen), keyEquivalent: "f") //!.keyEquivalentModifierMask = .AlternateKey | .CommandKey
windowMenu.addItemWithTitle("Close Window", action: #selector(window.performClose), keyEquivalent: "w")
windowMenu.addItem(NSMenuItem.separatorItem())
windowMenu.addItemWithTitle("Bring All to Front", action: #selector(NSApplication.arrangeInFront), keyEquivalent: "")

// Create the View
var view = NSView()
window.contentView = view
window.makeFirstResponder(view)
window.acceptsMouseMovedEvents = true

// Create the Context
var attrs:[NSOpenGLPixelFormatAttribute] = [UInt32(NSOpenGLPFADoubleBuffer), UInt32(NSOpenGLPFADepthSize), UInt32(24), UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion3_2Core), UInt32(0)]
var format = NSOpenGLPixelFormat(attributes: attrs)
var context = NSOpenGLContext(format: format!, shareContext: nil)
context!.setValues([1], forParameter: .GLCPSwapInterval)
context!.view = view
context!.makeCurrentContext()

// Setup observers
var running = true
NSNotificationCenter.defaultCenter().addObserverForName(NSWindowWillCloseNotification, object: window, queue: nil, usingBlock: {Void in running = false })
NSNotificationCenter.defaultCenter().addObserverForName(NSViewGlobalFrameDidChangeNotification, object: view, queue: nil, usingBlock: { Void in context!.update() })

// Finish loading
NSApp.setActivationPolicy(.Regular)
NSApp.mainMenu = menubar
NSApp.windowsMenu = windowMenu
NSApp.helpMenu = helpMenu
NSApp.servicesMenu = servicesMenu
NSApp.finishLaunching()

// Game Loop
while running {
  let event = NSApp.nextEventMatchingMask(0xfffffffffffffff, untilDate: NSDate.distantPast(), inMode: NSDefaultRunLoopMode, dequeue: true)
  if event != nil { NSApp.sendEvent(event!) }

  glViewport(0, 0, Int32(view.frame.size.width), Int32(view.frame.size.height))
  glClearColor(0.2, 0.2, 0.2, 0.0)
  glClear(UInt32(GL_COLOR_BUFFER_BIT))
  glFlush()
  context!.flushBuffer()
}

NSApp.terminate(nil)
