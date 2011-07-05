#import <SBAwayController.h>
#import <SBAwayDateView.h>
#import <SpringBoard-Class.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

static NSMutableArray *infoArray=nil;
static unsigned currentObjectIndex=-1;
static BOOL Respringing=NO;

@interface SBAwayDateView (added)
-(void)_TCIRespringNow;
@end
@interface UIApplication (SBAdditions)
-(void)_relaunchSpringBoardNow;
@end

natural_t get_free_memory() {
	mach_port_t host_port; mach_msg_type_number_t host_size;
	vm_size_t pagesize; host_port = mach_host_self();
	host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
	host_page_size(host_port, &pagesize);
	vm_statistics_data_t vm_stat;
	if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
		return 0;
	}
	natural_t mem_free = (vm_stat.free_count * pagesize) + (vm_stat.inactive_count * pagesize);
	return mem_free;
}

static NSMutableArray * fetchIPs(){
  
	NSMutableArray *ipsArray=[NSMutableArray array];
	NSString *address = @"error";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	success = getifaddrs(&interfaces);
	if (success == 0) {
		temp_addr = interfaces;
		while(temp_addr != NULL){
			if(temp_addr->ifa_addr->sa_family == AF_INET){
				address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				[ipsArray addObject:address];
			}
			temp_addr = temp_addr->ifa_next;
		}
	}

  freeifaddrs(interfaces);

  return ipsArray;
}

%hook SBAwayDateView
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	%orig;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_TCIRespringNow) object:nil];
	if (Respringing)
		return;
	[[%c(SBAwayController) sharedAwayController] restartDimTimer:8];
	UILabel *titleLabel=MSHookIvar<UILabel *>(self,"_titleLabel");
	[titleLabel setMinimumFontSize:9];
	if (!infoArray){
		infoArray=[[NSMutableArray array] retain];
		for (NSString *address in fetchIPs()){
			NSRange range=[address rangeOfString:@":"];
			if (range.location==NSNotFound && ![address isEqual:@"127.0.0.1"])
				[infoArray addObject:address];
		}
		int s=(get_free_memory()/1024)/1024;
		[infoArray  addObject:[NSString stringWithFormat:@"RAM: %dMB Free",s]];
		[infoArray addObject:@"Tap & hold to respring"];
	}
	unsigned totalObjects=[infoArray count];
	currentObjectIndex++;
	if (currentObjectIndex>totalObjects-1){
		currentObjectIndex=-1;
		[self updateLabels];
		return;
	}
	titleLabel.text=[infoArray objectAtIndex:currentObjectIndex];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	%orig;
	[self performSelector:@selector(_TCIRespringNow) withObject:nil afterDelay:2.0];
}
-(void)dealloc{
	[infoArray release];
	infoArray=nil;
	%orig;
}
%new(v@:)
-(void)_TCIRespringNow{
	UILabel *titleLabel=MSHookIvar<UILabel *>(self,"_titleLabel");
	if ([[titleLabel text] isEqualToString:@"Tap & hold to respring"]){
		titleLabel.text =@"Respringing...";
		Respringing=YES;
		[[UIApplication sharedApplication] performSelector:@selector(_relaunchSpringBoardNow) withObject:nil afterDelay:1];
	}
}

%end