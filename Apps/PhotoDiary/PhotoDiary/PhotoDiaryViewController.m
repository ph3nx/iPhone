#import "PhotoDiaryViewController.h"
#import "AudioPlayerController.h"
#import "Medium.h"
#import "ItemViewController.h"
#import "DiaryEntry.h"
#import "DiaryEntryCell.h"
#import "SlideShowController.h"

@interface PhotoDiaryViewController()<NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSData *cellData;
@property (nonatomic, copy) NSArray *searchResult;

@end

@implementation PhotoDiaryViewController

@synthesize tableView;
@synthesize itemViewController;
@synthesize managedObjectContext;
@synthesize fetchedResultsController;
@synthesize cellPrototype;
@synthesize slideShowController;
@synthesize audioPlayer;
@synthesize searchDisplayController;
@synthesize cellData;
@synthesize searchResult;

- (void)dealloc {
    NSNotificationCenter *theCenter = [NSNotificationCenter defaultCenter];

    [theCenter removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
    self.tableView = nil;
    self.itemViewController = nil;
    self.managedObjectContext = nil;
    self.fetchedResultsController = nil;
    self.cellPrototype = nil;
    self.cellData = nil;
    self.slideShowController = nil;
    self.audioPlayer = nil;
    self.searchDisplayController = nil;
    self.searchResult = nil;
    [super dealloc];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    NSNotificationCenter *theCenter = [NSNotificationCenter defaultCenter];
    
    [theCenter addObserver:self 
                  selector:@selector(managedObjectContextDidSave:)
                      name:NSManagedObjectContextDidSaveNotification 
                    object:nil];
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *theFetch = [[NSFetchRequest alloc] init];
    NSEntityDescription *theEntity = [NSEntityDescription entityForName:@"DiaryEntry" 
                                                 inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *theDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationTime" ascending:NO];
    
    theFetch.entity = theEntity;
    theFetch.sortDescriptors = [NSArray arrayWithObject:theDescriptor];
    return theFetch;
}

- (UITableView *)searchResultsTableView {
    return self.searchDisplayController.searchResultsTableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSFetchedResultsController *theController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
    NSError *theError = nil;
    
    theController.delegate = self;
    self.fetchedResultsController = theController;
    [theController release];
    if(![self.fetchedResultsController performFetch:&theError]) {
        NSLog(@"viewDidLoad: %@", theError);
    }
    self.cellData = [NSKeyedArchiver archivedDataWithRootObject:self.cellPrototype];
    [self.audioPlayer addViewToViewController:self.navigationController];
}

- (void)viewDidUnload {
    self.fetchedResultsController = nil;
    self.tableView = nil;
    self.itemViewController = nil;
    self.fetchedResultsController = nil;
    self.cellPrototype = nil;
    self.cellData = nil;
    self.slideShowController = nil;
    self.audioPlayer = nil;
    self.searchDisplayController = nil;
    [self.managedObjectContext reset];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inInterfaceOrientation {
    return YES;
}

- (DiaryEntryCell *)makeDiaryEntryCell {
    return [NSKeyedUnarchiver unarchiveObjectWithData:self.cellData];
}

- (NSString *)cellIdentifier {
    return self.cellPrototype.reuseIdentifier;
}

- (IBAction)showSlideShow {
    [self.navigationController pushViewController:self.slideShowController animated:YES];
}

- (IBAction)addItem {
    self.itemViewController.item = nil;
    [self.navigationController pushViewController:self.itemViewController animated:YES];
}

- (DiaryEntry *)entryForTableView:(UITableView *)inTableView atIndexPath:(NSIndexPath *)inIndexPath {
    if(inTableView == self.searchResultsTableView) {
        return [self.searchResult objectAtIndex:inIndexPath.row];
    }
    else {
        return [self.fetchedResultsController objectAtIndexPath:inIndexPath];
    }
}

- (IBAction)playSound:(id)inSender {
    NSIndexPath *theIndexPath = [NSIndexPath indexPathForRow:[inSender tag] inSection:0];
    UITableView *theTableView = self.searchDisplayController.active ? self.searchResultsTableView : self.tableView;
    DiaryEntry *theItem = [self entryForTableView:theTableView atIndexPath:theIndexPath];
    Medium *theMedium = [theItem mediumForType:kMediumTypeAudio];
    
    if(theMedium != nil) {
        self.audioPlayer.audioMedium = theMedium;
        [self.audioPlayer setVisible:YES animated:YES];
    }
}

- (void)applyDiaryEntry:(DiaryEntry *)inEntry toCell:(DiaryEntryCell *)inCell {
    UIImage *theImage = [UIImage imageWithData:inEntry.icon];
    
    [inCell setIcon:theImage];
    [inCell setText:inEntry.text];
    [inCell setDate:inEntry.creationTime];
}

- (void)managedObjectContextDidSave:(NSNotification *)inNotification {
    if(inNotification.object != self.managedObjectContext) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:inNotification];
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)inTableView {
    if(inTableView == self.searchResultsTableView) {
        return 1;
    }
    else {
        return [[self.fetchedResultsController sections] count];
    }
}

- (NSInteger)tableView:(UITableView *)inTableView numberOfRowsInSection:(NSInteger)inSection {
    if(inTableView == self.searchResultsTableView) {    
        return self.searchResult.count;
    }
    else {
        id<NSFetchedResultsSectionInfo> theInfo = [[self.fetchedResultsController sections] objectAtIndex:inSection];
        
        return [theInfo numberOfObjects];
    }
}

- (UITableViewCell *)tableView:(UITableView *)inTableView cellForRowAtIndexPath:(NSIndexPath *)inIndexPath {
    NSString *theIdentifier = self.cellIdentifier;
    DiaryEntryCell *theCell = (DiaryEntryCell *)[inTableView dequeueReusableCellWithIdentifier:theIdentifier];
    DiaryEntry *theEntry = [self entryForTableView:inTableView atIndexPath:inIndexPath];
    
    if(theCell == nil) {
        theCell = [self makeDiaryEntryCell];
        [theCell.imageControl addTarget:self 
                                 action:@selector(playSound:) 
                       forControlEvents:UIControlEventTouchUpInside];
    }
    theCell.imageControl.tag = inIndexPath.row;
    [self applyDiaryEntry:theEntry toCell:theCell];
    return theCell;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)inTableView heightForRowAtIndexPath:(NSIndexPath *)inIndexPath {
    return CGRectGetHeight(self.cellPrototype.frame);
}

- (void)tableView:(UITableView *)inTableView didSelectRowAtIndexPath:(NSIndexPath *)inIndexPath {
    DiaryEntry *theItem = [self entryForTableView:inTableView atIndexPath:inIndexPath];
    
    self.itemViewController.item = theItem;
    [self.navigationController pushViewController:self.itemViewController animated:YES];
}

- (void)tableView:(UITableView *)inTableView commitEditingStyle:(UITableViewCellEditingStyle)inStyle forRowAtIndexPath:(NSIndexPath *)inIndexPath {
    if(inStyle == UITableViewCellEditingStyleDelete) {
        DiaryEntry *theItem = [self entryForTableView:inTableView atIndexPath:inIndexPath];
		NSError *theError = nil;

		[self.managedObjectContext deleteObject:theItem];
		if([self.managedObjectContext save:&theError]) {
            if(inTableView == self.searchResultsTableView) {
                NSMutableArray *theResult = [self.searchResult mutableCopy];
                
                [theResult removeObjectAtIndex:inIndexPath.row];
                self.searchResult = theResult;
                [self.searchResultsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:inIndexPath] 
                                                   withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        else {
			NSLog(@"Unresolved error %@", theError);
		}
    }   
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)inController {
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)inController 
   didChangeObject:(id)inObject 
       atIndexPath:(NSIndexPath *)inIndexPath 
     forChangeType:(NSFetchedResultsChangeType)inType 
      newIndexPath:(NSIndexPath *)inNewIndexPath {
    id theCell;
    id theEntry;
	    
	switch(inType) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:inNewIndexPath] withRowAnimation:UITableViewRowAnimationRight];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:inIndexPath] withRowAnimation:UITableViewRowAnimationRight];
			break;
		case NSFetchedResultsChangeUpdate:
            theCell = [self.tableView cellForRowAtIndexPath:inIndexPath];
            theEntry = [self.fetchedResultsController objectAtIndexPath:inIndexPath];
            
            [self applyDiaryEntry:theEntry toCell:theCell];
			break;
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:inIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:inNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controller:(NSFetchedResultsController *)inController 
  didChangeSection:(id<NSFetchedResultsSectionInfo>)inSectionInfo 
           atIndex:(NSUInteger)inSectionIndex 
     forChangeType:(NSFetchedResultsChangeType)inType {
	
	switch(inType) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:inSectionIndex] 
                          withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:inSectionIndex] 
                          withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)inController {
	[self.tableView endUpdates];
}

#pragma mark UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)inController shouldReloadTableForSearchString:(NSString *)inSearchString {
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:@"text contains[cd] %@", inSearchString];
    NSArray *theObjects = self.fetchedResultsController.fetchedObjects;
    
    self.searchResult = [theObjects filteredArrayUsingPredicate:thePredicate];
    return YES;
}

#pragma mark SubviewControllerDelegate

- (void)subviewControllerWillDisappear:(SubviewController *)inController {
    AudioPlayerController *thePlayer = (AudioPlayerController *)inController;
    Medium *theMedium = thePlayer.audioMedium;

    if(theMedium != nil) {
        DiaryEntry *theEntry = theMedium.diaryEntry;
        
        [self.managedObjectContext refreshObject:theMedium mergeChanges:NO];
        [self.managedObjectContext refreshObject:theEntry mergeChanges:NO];
        thePlayer.audioMedium = nil;
    }
}

@end
