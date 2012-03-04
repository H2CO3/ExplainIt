/*
 * ExplainIt.m
 * ExplainIt
 *
 * Created by Árpád Goretity on 23/10/2011.
 * Released into the public domain
 */

#import <UIKit/UIKit.h>
#import <substrate.h>
#import <BingTranslate/BingTranslate.h>

static IMP _original_$_Application_$_init;
static IMP _original_$_TabController_$_initWithFrame_tabDocument_;

static id tabController = NULL;
UIMenuItem *menuItemTranslate = NULL;
BTClient *client = NULL;

#ifdef DEBUG
#define LOG(x) NSLog(@"ExplainIt: %s: line %d; %@", __func__, __LINE__, (x))
#else
#define LOG(x)
#endif

@interface EIDelegate: NSObject <BTClientDelegate> {
	UIView *view;
	UITextView *tv;
	UIButton *close;
	UILabel *label;
}

@end


@implementation EIDelegate

- (void) dealloc
{
	[view removeFromSuperview];
	[super dealloc];
}

- (void) close
{
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	[UIView beginAnimations:NULL context:NULL];
	[UIView setAnimationDuration:0.4];
	view.frame = CGRectMake(0, 480, 320, 480);
	[UIView commitAnimations];
}

- (void) bingTranslateClient:(BTClient *)client translatedText:(NSString *)text translation:(NSString *)translation
{
	if (view == NULL)
	{
		view = [[UIView alloc] initWithFrame:CGRectMake(0, 480, 320, 480)];
		view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
		UIWindow *window = [[objc_getClass("BrowserController") sharedBrowserController] window];
		[window addSubview:view];
		[view release];
	}
	if (close == NULL)
	{
		close = [UIButton buttonWithType:UIButtonTypeInfoLight];
		close.frame = CGRectMake(280, 0, 40, 40);
		[close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
		[view addSubview:close];
	}
	if (tv == NULL)
	{
		tv = [[UITextView alloc] initWithFrame:CGRectMake(0, 40, 320, 440)];
		tv.editable = NO;
		tv.backgroundColor = [UIColor clearColor];
		tv.font = [UIFont systemFontOfSize:16.0];
		tv.textColor = [UIColor whiteColor];
		[view addSubview:tv];
		[tv release];
	}
	if (label == NULL)
	{
		label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 240, 40)];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont boldSystemFontOfSize:20.0];
		label.textColor = [UIColor whiteColor];
		label.text = @"Translation result";
		label.textAlignment = UITextAlignmentCenter;
		[view addSubview:label];
		[label release];
	}
	tv.text = [[translation stringByReplacingOccurrencesOfString:@"\\u000a" withString:@"\n"] stringByReplacingOccurrencesOfString:@"\\u0009" withString:@"\t"];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	[UIView beginAnimations:NULL context:NULL];
	[UIView setAnimationDuration:0.4];
	view.frame = CGRectMake(0, 0, 320, 480);
	[UIView commitAnimations];
}

- (void) bingTranslateClient:(BTClient *)client errorOccurred:(NSError *)error
{
	[[[[UIAlertView alloc] initWithTitle:@"Error translating text" message:[error description] delegate:NULL cancelButtonTitle:@"Dismiss" otherButtonTitles:NULL] autorelease] show];
}

@end


id _modified_$_Application_$_init(id _self, SEL _cmd)
{
	id ret = _original_$_Application_$_init(_self, _cmd);
	menuItemTranslate = [[UIMenuItem alloc] initWithTitle:@"Translate" action:@selector(webViewSelectTranslate)];
	[[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObjects:menuItemTranslate, NULL]];
	[menuItemTranslate release];
	return ret;
}

id _modified_$_TabController_$_initWithFrame_tabDocument_(id _self, SEL _cmd, CGRect frame, id tabDocument)
{
	_self = _original_$_TabController_$_initWithFrame_tabDocument_(_self, _cmd, frame, tabDocument);
	tabController = _self;
	return _self;
}

void Application_$_webViewSelectTranslate(id _self, SEL _cmd)
{
	id webView = [[[tabController activeTabDocument] browserView] webView];
	NSString *selection = [webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString();"];
	NSString *currentSystemLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
	[client translateText:selection toLanguage:currentSystemLanguage];
}

__attribute__((constructor))
void init()
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	client = [[BTClient alloc] initWithAppID:@"BING_APP_ID_HERE"];
	EIDelegate *delegate = [[EIDelegate alloc] init];
	client.delegate = delegate;
	Class appClass = objc_getClass("Application");
	MSHookMessageEx(objc_getClass("TabController"), @selector(initWithFrame:tabDocument:), (IMP)_modified_$_TabController_$_initWithFrame_tabDocument_, &_original_$_TabController_$_initWithFrame_tabDocument_);
	MSHookMessageEx(appClass, @selector(init), (IMP)_modified_$_Application_$_init, &_original_$_Application_$_init);
	class_addMethod(appClass, @selector(webViewSelectTranslate), (IMP)Application_$_webViewSelectTranslate, "v@:");
}
