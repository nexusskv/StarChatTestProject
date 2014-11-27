//
//  MainViewController.m
//  StarChatTestProject
//
//  Created by rost on 18.11.14.
//  Copyright (c) 2014 rost. All rights reserved.
//

#import "STBubbleTableViewCell.h"
#import "Message.h"
#import "MainViewController.h"
#import "MessagesController.h"
#import "MessageDate.h"


#define TIMER_INTERVAL  10.0f

typedef NS_ENUM(NSUInteger, TypesMessages) {
    ServerMessage,
    UserMessage,
};


@interface MainViewController () <UITableViewDelegate, UITableViewDataSource, STBubbleTableViewCellDataSource, STBubbleTableViewCellDelegate, UITextFieldDelegate>
@property (nonatomic, strong) NSArray *sourceMessagesArray;
@property (nonatomic, strong) NSMutableArray *messagesArray;
@property (nonatomic, strong) UITableView *messagesTable;
@property (strong) NSTimer *createMessageTimer;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UITextField *messageField;
@property (nonatomic, assign) BOOL stopScrollToNewMessageFlag;
@end


@implementation MainViewController

#pragma mark - View life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Messages";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.stopScrollToNewMessageFlag = NO;       // DISABLE STOP SCROLL

    self.messagesTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.messagesTable.delegate = self;
    self.messagesTable.dataSource = self;
    
    self.messagesTable.backgroundColor = [UIColor colorWithRed:219.0f/255.0f green:226.0f/255.0f blue:237.0f/255.0f alpha:1.0f];
    self.messagesTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.messagesTable.contentInset = UIEdgeInsetsMake(-40.0f, 0.0f, 25.0f, 0.0f);
    [self.view addSubview:self.messagesTable];
    
    
    // CREATE BOTTOM VIEW
    [self createReplyView];
    
    
    // CONFIG CONSTRAINTS
    UIView *topIndentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 25.0f)];
    UIView *indentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height - 40.0f, self.view.frame.size.width, 40.0f)];
    [self.view addSubview:topIndentView];
    [self.view addSubview:indentView];
    
    self.messagesTable.translatesAutoresizingMaskIntoConstraints = NO;
    indentView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = @{@"topIndentView"    : topIndentView,
                            @"tableView"        : self.messagesTable,
                            @"indentView"       : indentView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topIndentView]-[tableView]-40-[indentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
   
    
    
    // SET OBSERVERS FOR KEYBOARD
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // GET WORDS FROM DB & SET TIMER FOR SHOW MESSAGES
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        self.sourceMessagesArray = [[NSMutableArray alloc] initWithArray:[[MessagesController shared] getPreparedMessages]];
        
        self.messagesArray = [[NSMutableArray alloc] initWithArray:[[MessagesController shared] getSavedMesages]];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.createMessageTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                                       target:self
                                                                     selector:@selector(timerSelector)
                                                                     userInfo:nil
                                                                      repeats:YES];
            
            if (([self.messagesArray count] > 5) && (!self.stopScrollToNewMessageFlag)) {
                [self.messagesTable reloadData];
                int lastRowNumber = (int)[self.messagesTable numberOfRowsInSection:0];
                NSIndexPath *messageIndex = [NSIndexPath indexPathForRow:lastRowNumber - 1 inSection:0];
                [self.messagesTable scrollToRowAtIndexPath:messageIndex atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        });
    });
}
#pragma mark -


#pragma mark - Selectors
- (void)createReplyView {
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height - 40.0f, self.view.frame.size.width, 40.0f)];
    UIView *whiteView = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 0.0f, self.view.frame.size.width - 110.0f, 40.0f)];
    whiteView.backgroundColor = [UIColor whiteColor];
    self.messageField = [[UITextField alloc] initWithFrame:CGRectMake(20.0f, 2.0f, self.bottomView.frame.size.width - 107.0f, 40.0f)];
    

    self.messageField.returnKeyType = UIReturnKeyDefault;
    self.messageField.font = [UIFont systemFontOfSize:15.0f];
    self.messageField.delegate = self;
    self.messageField.backgroundColor = [UIColor whiteColor];
    
    
    UIImage *rawEntryBackground = [UIImage imageNamed:@"MessageEntryInputField.png"];
    UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *entryImageView = [[UIImageView alloc] initWithImage:entryBackground];
    entryImageView.frame = CGRectMake(10.0f, 0.0f, self.bottomView.frame.size.width - 90.0f, 40.0f);
    entryImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    UIImage *rawBackground = [UIImage imageNamed:@"MessageEntryBackground.png"];
    UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:background];
    imageView.frame = CGRectMake(0, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    self.messageField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self.bottomView addSubview:imageView];
    [self.bottomView addSubview:whiteView];
    [self.bottomView addSubview:self.messageField];
    [self.bottomView addSubview:entryImageView];
    
    UIImage *sendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
 
    UIImage *selectedSendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
    
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame = CGRectMake(self.bottomView.frame.size.width - 69, 8, 63, 27);
    doneBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [doneBtn setTitle:@"Send" forState:UIControlStateNormal];
    
    [doneBtn setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.4] forState:UIControlStateNormal];
    doneBtn.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
    doneBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    
    [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(addReply) forControlEvents:UIControlEventTouchUpInside];
    [doneBtn setBackgroundImage:sendBtnBackground forState:UIControlStateNormal];
    [doneBtn setBackgroundImage:selectedSendBtnBackground forState:UIControlStateSelected];
    [self.bottomView addSubview:doneBtn];
    
    self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    [self.view addSubview:self.bottomView];
}
#pragma mark -


#pragma mark - UITableViewDatasource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messagesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Bubble Cell";
    
    STBubbleTableViewCell *cell = (STBubbleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[STBubbleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = self.messagesTable.backgroundColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.dataSource = self;
        cell.delegate = self;
    }
    
    Message *message = self.messagesArray[indexPath.row];
    
    cell.textLabel.font = [UIFont systemFontOfSize:14.0f];
    cell.imageView.image = message.avatar;
    
    if (message.appIdFlag) {
        NSRange firstSymbolRange = [message.message rangeOfString:@"#"];
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:message.message];
        [attributedText setAttributes:@{NSFontAttributeName             : [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize],
                                        NSForegroundColorAttributeName  : [UIColor redColor]}
                                range:NSMakeRange(firstSymbolRange.location, message.message.length - firstSymbolRange.location)];
        
        cell.textLabel.attributedText = attributedText;
    } else {
        cell.textLabel.text = message.message;
    }

    switch (message.typeMessage) {
        case ServerMessage: {
            cell.authorType = STBubbleTableViewCellAuthorTypeOther;
            cell.bubbleColor = STBubbleTableViewCellBubbleColorGray;
        }
            break;
        case UserMessage: {
            cell.authorType = STBubbleTableViewCellAuthorTypeSelf;
            cell.bubbleColor = STBubbleTableViewCellBubbleColorGreen;
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}
#pragma mark -


#pragma mark - UITableViewDelegate methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = self.messagesArray[indexPath.row];
    
    CGRect newRect = CGRectZero;
    
    if(message.avatar) {
        newRect = [message.message boundingRectWithSize:CGSizeMake(self.messagesTable.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - STBubbleImageSize - 8.0f - STBubbleWidthOffset, CGFLOAT_MAX)
                                  options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0f]}
                                  context:nil];
    } else {
        newRect = [message.message boundingRectWithSize:CGSizeMake(self.messagesTable.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - STBubbleWidthOffset, CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0f]}
                                                context:nil];
    }
    
    return newRect.size.height + 35.0f;
}
#pragma mark -


#pragma mark - STBubbleTableViewCellDataSource methods

- (CGFloat)minInsetForCell:(STBubbleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
        return 100.0f;
    
    return 50.0f;
}
#pragma mark -


#pragma mark - ScrollView Delegate methods
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self stopTableScrollToBottom];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView.panGestureRecognizer translationInView:scrollView].y > 0) {
        [self stopTableScrollToBottom];
    }
}
#pragma mark -


#pragma mark - UITextField Delegate method
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.text = @"";
}
#pragma mark -


#pragma mark - Selectors
- (void)addReply {
    [self.messageField resignFirstResponder];
    
    NSDictionary *saveValues = @{@"message"        : self.messageField.text,
                                 @"date"           : [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]],
                                 @"message_type"   : [NSNumber numberWithInteger:UserMessage],
                                 @"app_id_flag"    : @NO};
    
    [SAVE_DICTIONARY(saveValues)];
    
    NSString *string = [NSString stringWithFormat:@"%@ \n %@", [[MessageDate shared] getDate:[NSDate date]], self.messageField.text];
    if ([self.messageField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0)
        [self createMessage:string];
}

- (void)timerSelector {
    if ([self.sourceMessagesArray count] > 0) {
        NSDictionary *messageDictionary = self.sourceMessagesArray[arc4random_uniform((uint32_t)[self.sourceMessagesArray count])];
        
        [self createMessage:messageDictionary];
    }
}

- (void)createMessage:(id)sender {
    if (sender) {
        Message *freshMessage = [[Message alloc] init];
        
        if ([sender isKindOfClass:[NSDictionary class]]) {
            NSDictionary *messageDictionary = (NSDictionary *)sender;
            
            NSDictionary *saveValues = @{@"message"        : messageDictionary[@"words"],
                                         @"date"           : [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]],
                                         @"message_type"   : [NSNumber numberWithInteger:ServerMessage],
                                         @"app_id_flag"    : messageDictionary[@"appId"]};
            
            [SAVE_DICTIONARY(saveValues)];
            
            freshMessage.message = [NSString stringWithFormat:@"%@ \n %@", [[MessageDate shared] getDate:[NSDate date]], messageDictionary[@"words"]];
            freshMessage.appIdFlag = [messageDictionary[@"appId"] boolValue];
            freshMessage.typeMessage = ServerMessage;
        } else if ([sender isKindOfClass:[NSString class]]){
            freshMessage.message = (NSString *)sender;
            freshMessage.typeMessage = UserMessage;
        }
  
        if (freshMessage) {
            if ([self.messagesArray count] > 0) {
                [self.messagesArray addObject:freshMessage];
            } else {
                self.messagesArray = [NSMutableArray arrayWithObject:freshMessage];
            }
       
            [self.messagesTable reloadData];
            
            if (([self.messagesArray count] > 5) && (!self.stopScrollToNewMessageFlag)) {
                int lastRowNumber = (int)[self.messagesTable numberOfRowsInSection:0];
                NSIndexPath *messageIndex = [NSIndexPath indexPathForRow:lastRowNumber - 1 inSection:0];
                [self.messagesTable scrollToRowAtIndexPath:messageIndex atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
    }
}

- (BOOL)detectTopOfTable {
    NSIndexPath *firstVisibleIndexPath = [[self.messagesTable indexPathsForVisibleRows] objectAtIndex:0];
    
    if (firstVisibleIndexPath.row < 6)
        return YES;
    
    return NO;
}

- (void)stopTableScrollToBottom {
    if ([self detectTopOfTable])
        self.stopScrollToNewMessageFlag = YES;
    else
        self.stopScrollToNewMessageFlag = NO;    
}
#pragma mark -


#pragma mark - Keyboard Observer methods
- (void)keyboardWillShow:(NSNotification *)note
{
    CGFloat height = [[note.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    [UIView animateWithDuration:0.4f animations:^ {
        self.view.frame = CGRectMake(0, -height, self.view.bounds.size.width, self.view.bounds.size.height);
    }];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    [UIView animateWithDuration:0.4f animations:^ {
        self.view.frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height);
    }];
}
#pragma mark -


#pragma mark -
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}
#pragma mark -


#pragma mark - Destructor
- (void)dealloc {
    if (self.createMessageTimer) {
        [self.createMessageTimer invalidate], self.createMessageTimer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark -


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    self.sourceMessagesArray = nil;
    self.messagesArray = nil;
}


@end
