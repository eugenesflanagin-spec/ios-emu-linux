/* HelloLinux: a tiny iOS app written in plain C against the Objective-C runtime,
 * built on Linux with clang + ld64.lld and hand-written .tbd stubs (no Apple SDK). */
typedef void *id; typedef void *SEL; typedef void *Class; typedef signed char BOOL;
typedef double CGFloat; typedef struct { CGFloat x, y, w, h; } CGRect;
typedef unsigned long size_t;
extern id objc_msgSend(void); extern Class objc_getClass(const char *); extern SEL sel_registerName(const char *);
extern Class objc_allocateClassPair(Class, const char *, size_t); extern BOOL class_addMethod(Class, SEL, void *, const char *);
extern void objc_registerClassPair(Class);
extern int UIApplicationMain(int, char **, id, id);
extern id CFStringCreateWithCString(void *, const char *, unsigned int);
#define S(s) sel_registerName(s)
#define C(c) ((id)objc_getClass(c))
#define STR(s) CFStringCreateWithCString(0, s, 0x08000100)
static id m0(id o, const char *s) { return ((id(*)(id, SEL))objc_msgSend)(o, S(s)); }
static id m1(id o, const char *s, id a) { return ((id(*)(id, SEL, id))objc_msgSend)(o, S(s), a); }
static id mi(id o, const char *s, long a) { return ((id(*)(id, SEL, long))objc_msgSend)(o, S(s), a); }
static id mr(id o, const char *s, CGRect r) { return ((id(*)(id, SEL, CGRect))objc_msgSend)(o, S(s), r); }
static id mf(id o, const char *s, CGFloat f) { return ((id(*)(id, SEL, CGFloat))objc_msgSend)(o, S(s), f); }
static id window;

static BOOL didFinish(id self, SEL cmd, id app, id opts) {
    CGRect b = ((CGRect(*)(id, SEL))objc_msgSend)(m0(C("UIScreen"), "mainScreen"), S("bounds"));
    window = mr(m0(C("UIWindow"), "alloc"), "initWithFrame:", b);
    id vc = m0(m0(C("UIViewController"), "alloc"), "init");
    id view = m0(vc, "view");
    m1(view, "setBackgroundColor:", m0(C("UIColor"), "systemIndigoColor"));
    id label = mr(m0(C("UILabel"), "alloc"), "initWithFrame:", b);
    m1(label, "setText:", STR("Hello from Linux!\n\nThis app was built on Garuda\nwith clang + ld64.lld,\nfake-signed with ldid,\nand installed by uicache."));
    mi(label, "setNumberOfLines:", 0);
    mi(label, "setTextAlignment:", 1);
    m1(label, "setTextColor:", m0(C("UIColor"), "whiteColor"));
    m1(label, "setFont:", mf(C("UIFont"), "boldSystemFontOfSize:", 26.0));
    m1(view, "addSubview:", label);
    m1(window, "setRootViewController:", vc);
    m0(window, "makeKeyAndVisible");
    return 1;
}

int main(int argc, char **argv) {
    Class d = objc_allocateClassPair(objc_getClass("UIResponder"), "HLAppDelegate", 0);
    class_addMethod(d, S("application:didFinishLaunchingWithOptions:"), (void *)didFinish, "c@:@@");
    objc_registerClassPair(d);
    return UIApplicationMain(argc, argv, 0, STR("HLAppDelegate"));
}
