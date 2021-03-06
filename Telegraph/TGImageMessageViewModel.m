#import "TGImageMessageViewModel.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGModernConversationItem.h"

#import "TGModernView.h"

#import "TGTelegraphConversationMessageAssetsSource.h"
#import <LegacyComponents/TGDoubleTapGestureRecognizer.h>

#import "TGModernViewContext.h"
#import "TGTelegraph.h"

#import "TGModernLetteredAvatarViewModel.h"
#import "TGMessageImageViewModel.h"
#import "TGModernImageViewModel.h"
#import "TGModernFlatteningViewModel.h"
#import "TGModernDateViewModel.h"
#import "TGModernClockProgressViewModel.h"
#import "TGModernButtonViewModel.h"
#import "TGModernCheckButtonViewModel.h"

#import "TGModernRemoteImageView.h"

#import "TGMessageImageView.h"
#import "TGMessageImageViewTimestampView.h"

#import "TGInstantPreviewTouchAreaModel.h"

#import <LegacyComponents/TGTimerTarget.h>

#import "TGContentBubbleViewModel.h"
#import "TGReplyHeaderModel.h"

#import "TGReusableLabel.h"

#import "TGTextMessageBackgroundViewModel.h"
#import "TGModernFlatteningViewModel.h"
#import "TGModernTextViewModel.h"

#import "TGContentBubbleViewModel.h"

#import "TGMessageViewsViewModel.h"
#import "TGModernButtonView.h"
#import "TGModernButtonViewModel.h"

#import "TGMessageReplyButtonsModel.h"

#import "TGAudioWebpageFooterModel.h"
#import "TGArticleWebpageFooterModel.h"
#import "TGStickerWebpageFooterModel.h"
#import "TGMusicWebpageFooterModel.h"
#import "TGDocumentWebpageFooterModel.h"
#import "TGRoundVideoWebpageFooterModel.h"

#import "TGPresentation.h"

@interface TGImageMessageViewModel () <UIGestureRecognizerDelegate, TGDoubleTapGestureRecognizerDelegate, TGMessageImageViewDelegate>
{
    TGModernViewContext *_context;
    
    bool _incoming;
    TGMessageDeliveryState _deliveryState;
    bool _read;
    int _date;
    int32_t _messageLifetime;
    
    NSString *_legacyThumbnailCacheUri;
    CGSize _originalImageSize;
    
    CGSize _imageSize;
    TGMessageGroupPositionFlags _imagePosition;
    
    bool _hasAvatar;
    bool _isBot;
    bool _byAdmin;
    bool _savedMessage;
    
    float _progress;
    bool _progressVisible;
    
    bool _displayCaption;
    
    bool _isMessageViewed;
    NSTimeInterval _messageViewDate;
    
    TGDoubleTapGestureRecognizer *_boundDoubleTapRecognizer;
    TGDoubleTapGestureRecognizer *_boundBackgroundDoubleTapRecognizer;
    
    NSArray *_currentLinkSelectionViews;
    
    TGModernFlatteningViewModel *_adminContentModel;
    TGModernDateViewModel *_dateModel;
    TGModernClockProgressViewModel *_progressModel;
    TGModernImageViewModel *_checkFirstModel;
    TGModernImageViewModel *_checkSecondModel;
    TGModernTextViewModel *_authorSignatureModel;
    NSString *_authorSignature;
    
    bool _checkFirstEmbeddedInContent;
    bool _checkSecondEmbeddedInContent;
    
    TGModernImageViewModel *_unsentButtonModel;
    UITapGestureRecognizer *_unsentButtonTapRecognizer;
    
    TGInstantPreviewTouchAreaModel *_instantPreviewTouchAreaModel;
    
    UIImageView *_temporaryHighlightView;
    
    CGPoint _boundOffset;
    CGPoint _imageOrigin;
    
    NSTimer *_viewDateTimer;
    
    TGModernTextViewModel *_forwardedHeaderModel;
    TGModernTextViewModel *_authorNameModel;
    TGModernTextViewModel *_viaUserModel;
    TGUser *_viaUser;
    TGReplyHeaderModel *_replyHeaderModel;
    
    int32_t _replyMessageId;
    int64_t _forwardedPeerId;
    int32_t _forwardedMessageId;
    
    NSString *_caption;
    TGMessageViewCountContentProperty *_messageViews;
    TGMessageViewsViewModel *_messageViewsModel;
    TGModernLabelViewModel *_editedLabelModel;
    
    TGModernButtonViewModel *_actionButtonModel;
    
    TGMessage *_replyHeader;
    id _replyAuthor;
    id _forwardPeer;
    bool _isChannel;
    id _forwardAuthor;
    NSArray *_textCheckingResults;
    UIColor *_authorNameColor;
    
    TGMessageReplyButtonsModel *_replyButtonsModel;
    TGBotReplyMarkup *_replyMarkup;
    SMetaDisposable *_callbackButtonInProgressDisposable;
    
    bool _isEdited;
    
    TGWebpageFooterModel *_webPageFooterModel;
    bool _boundToContainer;
    TGWebPageMediaAttachment *_webPage;
    bool _skipContentModelAnimation;
    
    TGModernButtonViewModel *_groupCheckAreaModel;
    TGModernCheckButtonViewModel *_groupCheckButtonModel;
    
    NSString *_currentBaseUri;
}

@end

@implementation TGImageMessageViewModel

static CTFontRef textFontForSize(CGFloat size)
{
    static CTFontRef font = NULL;
    static int cachedSize = 0;
    
    if ((int)size != cachedSize || font == NULL)
    {
        font = TGCoreTextSystemFontOfSize(size);
        cachedSize = (int)size;
    }
    
    return font;
}

- (instancetype)initWithMessage:(TGMessage *)message imageInfo:(TGImageInfo *)imageInfo authorPeer:(id)authorPeer context:(TGModernViewContext *)context forwardPeer:(id)forwardPeer forwardAuthor:(id)forwardAuthor forwardMessageId:(int32_t)forwardMessageId replyHeader:(TGMessage *)replyHeader replyAuthor:(id)replyAuthor viaUser:(TGUser *)viaUser
{
    return [self initWithMessage:message imageInfo:imageInfo authorPeer:authorPeer context:context forwardPeer:forwardPeer forwardAuthor:forwardAuthor forwardMessageId:forwardMessageId replyHeader:replyHeader replyAuthor:replyAuthor viaUser:viaUser caption:nil textCheckingResults:nil];
}

- (instancetype)initWithMessage:(TGMessage *)message imageInfo:(TGImageInfo *)imageInfo authorPeer:(id)authorPeer context:(TGModernViewContext *)context forwardPeer:(id)forwardPeer forwardAuthor:(id)forwardAuthor forwardMessageId:(int32_t)forwardMessageId replyHeader:(TGMessage *)replyHeader replyAuthor:(id)replyAuthor viaUser:(TGUser *)viaUser caption:(NSString *)caption textCheckingResults:(NSArray *)textCheckingResults
{
    return [self initWithMessage:message imageInfo:imageInfo authorPeer:authorPeer context:context forwardPeer:forwardPeer forwardAuthor:forwardAuthor forwardMessageId:forwardMessageId replyHeader:replyHeader replyAuthor:replyAuthor viaUser:viaUser caption:caption textCheckingResults:textCheckingResults webPage:nil];
}

- (instancetype)initWithMessage:(TGMessage *)message imageInfo:(TGImageInfo *)imageInfo authorPeer:(id)authorPeer context:(TGModernViewContext *)context forwardPeer:(id)forwardPeer forwardAuthor:(id)forwardAuthor forwardMessageId:(int32_t)forwardMessageId replyHeader:(TGMessage *)replyHeader replyAuthor:(id)replyAuthor viaUser:(TGUser *)viaUser caption:(NSString *)caption textCheckingResults:(NSArray *)textCheckingResults webPage:(TGWebPageMediaAttachment *)webPage {
    self = [super initWithAuthorPeer:authorPeer context:context];
    if (self != nil)
    {
        _callbackButtonInProgressDisposable = [[SMetaDisposable alloc] init];
        
        _previewEnabled = true;
        _canDownload = true;
        
        _context = context;
        
        _webPage = webPage;
        
        bool isChannel = [authorPeer isKindOfClass:[TGConversation class]];
        
        _authorPeer = authorPeer;
        
        if (message.groupedId != 0)
            _positionFlags = TGMessageGroupPositionUnknown;
        
        if (message.isEdited && (_authorPeer == nil || ![_authorPeer isKindOfClass:[TGConversation class]] || !((TGConversation *)_authorPeer).isChannel || ((TGConversation *)_authorPeer).isChannelGroup)) {
            _isEdited = true;
        }
        
        TGForwardedMessageMediaAttachment *forwardAttachment = nil;
        for (TGMediaAttachment *attachment in message.mediaAttachments)
        {
            if (attachment.type == TGForwardedMessageMediaAttachmentType)
            {
                forwardAttachment = (TGForwardedMessageMediaAttachment *)attachment;
                break;
            }
        }
        _savedMessage = forwardAttachment != nil && context.isSavedMessages && forwardAttachment.forwardSourcePeerId != message.cid;
        bool hasForwardPostId = forwardAttachment.forwardPostId != 0 || forwardAttachment.forwardMid != 0;
        
        _incoming = !message.outgoing;
        _incomingAppearance = _incoming || isChannel || _savedMessage;
        _deliveryState = message.deliveryState;
        _read = ![_context isMessageUnread:message];
        _date = (int32_t)message.date;
        _messageViews = message.viewCount;
        _message = message;
        _textCheckingResults = textCheckingResults;
        _byAdmin = [_context isByAdmin:_message];
        
        if ([authorPeer isKindOfClass:[TGUser class]]) {
            TGUser *author = authorPeer;
            _isBot = author.kind == TGUserKindBot || author.kind == TGUserKindSmartBot;
        }
        
        _replyHeader = replyHeader;
        _replyAuthor = replyAuthor;
        _forwardPeer = forwardPeer;
        _viaUser = viaUser;
        _isChannel = isChannel;
        _caption = caption;
        _forwardedMessageId = forwardMessageId;
        _forwardAuthor = forwardAuthor;
        
        NSString *imageUri = [imageInfo imageUrlForLargestSize:NULL];
        imageUri = [self updateImageUri:imageUri];
        
        static UIColor *incomingDateColor = nil;
        static UIColor *outgoingDateColor = nil;
        
        static TGTelegraphConversationMessageAssetsSource *assetsSource = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            assetsSource = [TGTelegraphConversationMessageAssetsSource instance];
            
            incomingDateColor = UIColorRGBA(0x525252, 0.6f);
            outgoingDateColor = UIColorRGBA(0x008c09, 0.8f);
        });
        
        _hasAvatar = authorPeer != nil && ![authorPeer isKindOfClass:[TGConversation class]];
        if ([authorPeer isKindOfClass:[TGConversation class]]) {
            if (context.isAdminLog || context.isSavedMessages) {
                _hasAvatar = true;
            }
        }
        
        static UIImage *placeholderImage = nil;
        static dispatch_once_t onceToken1;
        dispatch_once(&onceToken1, ^
        {
            placeholderImage = [TGImageNamed(@"ModernMessageImagePlaceholder.png") stretchableImageWithLeftCapWidth:16 topCapHeight:16];
        });
        
        _needsEditingCheckButton = true;
        
        _mid = message.mid;
        _groupedId = message.groupedId;
        _deliveryState = message.deliveryState;
        _date = (int32_t)message.date;
        _messageLifetime = message.messageLifetime;
        
        CGSize imageSize = CGSizeZero;
        _imageModel = [[TGMessageImageViewModel alloc] initWithUri:imageUri];
        [_imageModel setPresentation:_context.presentation];
        
        CGSize imageOriginalSize = CGSizeMake(1, 1);
        [imageInfo imageUrlForLargestSize:&imageOriginalSize];
        imageSize = imageOriginalSize;
        
        _imageModel.skipDrawInContext = true;
        
        CGSize renderSize = CGSizeZero;
        [TGImageMessageViewModel calculateImageSizesForImageSize:imageSize thumbnailSize:&imageSize renderSize:&renderSize squareAspect:message.messageLifetime > 0 && message.messageLifetime <= 60 && message.layer >= 17 && !_ignoreMessageLifetime];
        
        _originalImageSize = imageSize;
        
        _imageModel.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        
        [self setupContentModel:nil];
        
        [self addSubmodel:_imageModel];
        
        if (_messageLifetime != 0 && message.layer >= 17)
        {
            _isMessageViewed = [context isSecretMessageViewed:_mid];
            _messageViewDate = [context secretMessageViewDate:_mid];
        }
        
        if (!_incoming)
        {
            if (_deliveryState == TGMessageDeliveryStateFailed)
            {
                [self addSubmodel:[self unsentButtonModel]];
            }
        }
        
        bool isBot = false;
        if ([authorPeer isKindOfClass:[TGUser class]]) {
            if (((TGUser *)authorPeer).kind == TGUserKindBot || ((TGUser *)authorPeer).kind ==  TGUserKindSmartBot) {
                isBot = true;
            }
        }
        
        bool forwardedFromChannel = false;
        
        if (_incomingAppearance && [forwardPeer isKindOfClass:[TGConversation class]]) {
            TGConversation *conversation = forwardPeer;
            if (conversation.isChannel && !conversation.isChannelGroup) {
                forwardedFromChannel = true;
            }
        }
        
        if (_incomingAppearance && ((_savedMessage && hasForwardPostId) || isChannel || _context.isBot || _context.isPublicGroup || isBot || forwardedFromChannel) && !_context.isAdminLog) {
            [_backgroundModel setPartialMode:false];
            
            _actionButtonModel = [[TGModernButtonViewModel alloc] init];
            _actionButtonModel.image = _savedMessage ? [[TGTelegraphConversationMessageAssetsSource instance] systemGoToButton] : [[TGTelegraphConversationMessageAssetsSource instance] systemShareButton];
            _actionButtonModel.modernHighlight = true;
            _actionButtonModel.frame = CGRectMake(0.0f, 0.0f, 29.0f, 29.0f);
            [self addSubmodel:_actionButtonModel];
        }
        
        TGBotReplyMarkup *replyMarkup = message.replyMarkup;
        if (replyMarkup != nil && replyMarkup.isInline) {
            _replyMarkup = replyMarkup;
            _replyButtonsModel = [[TGMessageReplyButtonsModel alloc] init];
            __weak TGImageMessageViewModel *weakSelf = self;
            _replyButtonsModel.buttonActivated = ^(TGBotReplyMarkupButton *button, NSInteger index) {
                __strong TGImageMessageViewModel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{@"mid": @(strongSelf->_mid), @"command": button.text}];
                    if (button.action != nil) {
                        dict[@"action"] = button.action;
                    }
                    dict[@"index"] = @(index);
                    [strongSelf->_context.companionHandle requestAction:@"activateCommand" options:dict];
                }
            };
            [_replyButtonsModel setReplyMarkup:replyMarkup hasReceipt:false];
            [self addSubmodel:_replyButtonsModel];
        }
    }
    return self;
}

- (void)enableInstantPreview
{
    if (_instantPreviewTouchAreaModel == nil)
    {
        __weak TGImageMessageViewModel *weakSelf = self;
        _instantPreviewTouchAreaModel = [[TGInstantPreviewTouchAreaModel alloc] init];
        _instantPreviewTouchAreaModel.touchesBeganAction = ^
        {
            __strong TGImageMessageViewModel *strongSelf = weakSelf;
            if (strongSelf != nil)
                [strongSelf activateMedia:true];
        };
        _instantPreviewTouchAreaModel.touchesCompletedAction = ^
        {
            __strong TGImageMessageViewModel *strongSelf = weakSelf;
            if (strongSelf != nil)
                [strongSelf deactivateMedia:true];
        };
        
        _instantPreviewTouchAreaModel.viewUserInteractionDisabled = !_mediaIsAvailable || _progressVisible;
        
        [self addSubmodel:_instantPreviewTouchAreaModel];
    }
}

- (NSString *)stringForLifetime:(int32_t)remainingSeconds
{
    return [TGStringUtils stringForShortMessageTimerSeconds:remainingSeconds];
}

- (NSString *)defaultAdditionalDataString
{
    if (self.isSecret)
    {
        if (_isMessageViewed)
        {
            if (ABS(_messageViewDate - DBL_EPSILON) > 0.0)
            {
                NSTimeInterval endTime = _messageViewDate + _messageLifetime;
                int remainingSeconds = MAX(0, (int)(endTime - CFAbsoluteTimeGetCurrent()));
                return [self stringForLifetime:remainingSeconds];
            }
            return [self stringForLifetime:0];
        }
        else
            return [self stringForLifetime:_messageLifetime];
    }
    
    return nil;
}

- (void)setIsSecret:(bool)isSecret
{
    _isSecret = isSecret;
    
    [self updateImageOverlay:false];
}

- (void)updateImage
{
}

- (void)updateImageInfo:(TGImageInfo *)imageInfo
{
    NSString *imageUri = [imageInfo imageUrlForLargestSize:NULL];
    [self updateImageUri:imageUri];
}

- (NSString *)updateImageUri:(NSString *)imageUri
{
    if (imageUri == nil) {
        imageUri = @"photo-thumbnail://?";
    } else if ([imageUri hasPrefix:@"photo-thumbnail://?"])
    {
        NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:[imageUri substringFromIndex:@"photo-thumbnail://?".length]];
        _legacyThumbnailCacheUri = dict[@"legacy-thumbnail-cache-url"];
    }
    else if ([imageUri hasPrefix:@"video-thumbnail://?"])
    {
        NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:[imageUri substringFromIndex:@"video-thumbnail://?".length]];
        _legacyThumbnailCacheUri = dict[@"legacy-thumbnail-cache-url"];
    }
    else if ([imageUri hasPrefix:@"animation-thumbnail://?"])
    {
        NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:[imageUri substringFromIndex:@"animation-thumbnail://?".length]];
        _legacyThumbnailCacheUri = dict[@"legacy-thumbnail-cache-url"];
    }
    
    _currentBaseUri = imageUri;
    
    
    if ((_positionFlags == TGMessageGroupPositionNone && (_replyHeader != nil || _caption.length != 0 || (_forwardPeer != nil && !_context.isSavedMessages) || _viaUser != nil || _webPage != nil)) || (_positionFlags != TGMessageGroupPositionNone && (_backgroundModel != nil || [self hasHeader])))
        imageUri = [imageUri stringByAppendingString:@"&flat=1"];
    
    int positionFlags = [self visiblePositionFlags];
    if (positionFlags != 0)
        imageUri = [imageUri stringByAppendingFormat:@"&position=%d", positionFlags];
    
    [_imageModel setUri:imageUri];
    
    return imageUri;
}

- (void)setAuthorNameColor:(UIColor *)authorNameColor
{
    _authorNameModel.textColor = authorNameColor;
    _authorNameColor = authorNameColor;
}

- (void)setAuthorSignature:(NSString *)authorSignature {
    if (_caption.length != 0) {
        _authorSignatureModel.text = authorSignature;
    }
    _authorSignature = authorSignature;
    
    [_imageModel setTimestampString:[self timestampString] signatureString:_authorSignature displayCheckmarks:!_incoming && !(_incomingAppearance && _context.isSavedMessages) && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:false];
}

+ (void)calculateImageSizesForImageSize:(in CGSize)imageSize thumbnailSize:(out CGSize *)thumbnailSize renderSize:(out CGSize *)renderSize squareAspect:(bool)squareAspect
{
    [self calculateImageSizesForImageSize:imageSize thumbnailSize:thumbnailSize renderSize:renderSize squareAspect:squareAspect larger:false];
}

+ (void)calculateImageSizesForImageSize:(in CGSize)imageSize thumbnailSize:(out CGSize *)thumbnailSize renderSize:(out CGSize *)renderSize squareAspect:(bool)squareAspect larger:(bool)larger
{
    if (squareAspect)
    {
        CGFloat squareSide = 180.0f;
        
        if (imageSize.width > imageSize.height)
        {
            if (renderSize)
                *renderSize = CGSizeMake(imageSize.width * squareSide / imageSize.height, squareSide);
        }
        else
        {
            if (renderSize)
                *renderSize = CGSizeMake(squareSide, imageSize.height * squareSide / imageSize.width);
        }
        
        if (thumbnailSize)
            *thumbnailSize = CGSizeMake(squareSide, squareSide);
        
        return;
    }
    
    CGFloat maxSide = 228.0f;
    static bool hasTallScreen = true;
    static bool hasLargeScreen = true;
    static bool hasVeryLargeScreen = true;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hasTallScreen = [TGViewController hasTallScreen];
        hasLargeScreen = [TGViewController hasLargeScreen];
        hasVeryLargeScreen = [TGViewController hasVeryLargeScreen];
    });
    if (hasVeryLargeScreen && !hasTallScreen) {
        maxSide += 71.0f;
    }
    else if (hasLargeScreen) {
        maxSide += 51.0f;
    }
    
    if (larger) {
        maxSide += 25.0f;
    }
    
    CGSize imageTargetMaxSize = CGSizeMake(maxSide, maxSide);
    CGSize imageScalingMaxSize = CGSizeMake(imageTargetMaxSize.width - 18.0f, imageTargetMaxSize.height - 18.0f);
    CGSize imageTargetMinSize = CGSizeMake(128.0f, 128.f);
    
    CGFloat imageAspect = 1.0f;
    if (imageSize.width > 1.0f - FLT_EPSILON && imageSize.height > 1.0f - FLT_EPSILON)
        imageAspect = imageSize.width / imageSize.height;
    
    if (imageSize.width < imageScalingMaxSize.width || imageSize.height < imageScalingMaxSize.height)
    {
        if (imageSize.width <= FLT_EPSILON || imageSize.height <= FLT_EPSILON)
            imageSize = imageTargetMinSize;
    }
    else
    {
        if (imageSize.width > imageTargetMaxSize.width)
        {
            imageSize.width = imageTargetMaxSize.width;
            imageSize.height = CGFloor(imageTargetMaxSize.width / imageAspect);
        }
        
        if (imageSize.height > imageTargetMaxSize.height)
        {
            imageSize.width = CGFloor(imageTargetMaxSize.height * imageAspect);
            imageSize.height = imageTargetMaxSize.height;
        }
    }
    
    if (renderSize != NULL)
        *renderSize = imageSize;
    
    imageSize.width = MIN(imageTargetMaxSize.width, imageSize.width);
    imageSize.height = MIN(imageTargetMaxSize.height, imageSize.height);
    
    imageSize.width = MAX(imageTargetMinSize.width, imageSize.width);
    imageSize.height = MAX(imageTargetMinSize.height, imageSize.height);
    
    if (thumbnailSize != NULL)
        *thumbnailSize = imageSize;
}

- (UIImage *)dateBackground
{
    static UIImage *dateBackgroundImage = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        dateBackgroundImage = [TGImageNamed(@"ModernMessageImageDateBackground.png") stretchableImageWithLeftCapWidth:9 topCapHeight:9];
    });
    
    return dateBackgroundImage;
}

- (UIColor *)dateColor
{
    return [UIColor whiteColor];
}

- (int)clockProgressType
{
    return TGModernClockProgressTypeOutgoingMediaClock;
}

- (CGPoint)dateOffset
{
    return CGPointZero;
}

- (bool)instantPreviewGesture
{
    return false;
}

- (TGMessageGroupPositionFlags)visiblePositionFlags
{
    bool hasTopCorners = true;
    bool hasBottomCorners = true;
    
    bool hasCaption = _caption.length > 0 && _positionFlags == TGMessageGroupPositionNone;
    if (hasCaption)
        hasBottomCorners = false;
    
    if ((!hasBottomCorners && _authorPeer != nil) || _replyHeader != nil || (_forwardPeer != nil && !_context.isSavedMessages) || _viaUser != nil)
        hasTopCorners = false;
    
    if (_positionFlags != TGMessageGroupPositionNone && _positionFlags != TGMessageGroupPositionUnknown)
    {
        TGMessageGroupPositionFlags position = _positionFlags;
        if (!hasTopCorners)
            position &= ~TGMessageGroupPositionTop;
        if (position == TGMessageGroupPositionNone)
            position = TGMessageGroupPositionInside;
        return position;
    }
    
    TGMessageGroupPositionFlags position = TGMessageGroupPositionNone;
    if (!hasTopCorners && !hasBottomCorners)
    {
        position = TGMessageGroupPositionInside;
    }
    else
    {
        position = TGMessageGroupPositionLeft | TGMessageGroupPositionRight;
        if (hasTopCorners)
            position |= TGMessageGroupPositionTop;
        if (hasBottomCorners)
            position |= TGMessageGroupPositionBottom;
    }
    
    return position;
}

- (void)setTemporaryHighlighted:(bool)temporaryHighlighted viewStorage:(TGModernViewStorage *)__unused viewStorage
{
    if (_backgroundModel != nil && _positionFlags == TGMessageGroupPositionNone)
    {
        if (temporaryHighlighted)
            [_backgroundModel setHighlightedIfBound];
        else
            [_backgroundModel clearHighlight];
    }

    if ([_imageModel boundView] != nil)
    {
        if (temporaryHighlighted)
        {
            if (_temporaryHighlightView == nil)
            {
                bool hasBackground = [self hasHeader] || _backgroundModel != nil;
                
                CGFloat inset = !hasBackground ? 1.0f : 0.0f;
                const int smallRadius = !hasBackground ? 3.0f : 3.0f;
                const int bigRadius = hasBackground ? 15.0f : 16.0f;
                
                int topLeftRadius = smallRadius;
                int topRightRadius = smallRadius;
                int bottomLeftRadius = smallRadius;
                int bottomRightRadius = smallRadius;
                
                int position = [self visiblePositionFlags];
                if (position == TGMessageGroupPositionNone)
                    topLeftRadius = topRightRadius = bottomLeftRadius = bottomRightRadius = bigRadius;
                else if (position == TGMessageGroupPositionInside)
                    topLeftRadius = topRightRadius = bottomLeftRadius = bottomRightRadius = smallRadius;
                
                if (position & TGMessageGroupPositionTop && position & TGMessageGroupPositionLeft)
                    topLeftRadius = bigRadius;
                if (position & TGMessageGroupPositionTop && position & TGMessageGroupPositionRight)
                    topRightRadius = bigRadius;
                if (position & TGMessageGroupPositionBottom && position & TGMessageGroupPositionLeft)
                    bottomLeftRadius = bigRadius;
                if (position & TGMessageGroupPositionBottom && position & TGMessageGroupPositionRight)
                    bottomRightRadius = bigRadius;
                
                CGFloat leftMax = MAX(topLeftRadius, bottomLeftRadius);
                CGFloat rightMax = MAX(topRightRadius, bottomRightRadius);
                CGFloat topMax = MAX(topLeftRadius, topRightRadius);
                CGFloat bottomMax = MAX(bottomLeftRadius, bottomRightRadius);
                CGRect rect = CGRectMake(0.0f, 0.0f, leftMax + rightMax, topMax + bottomMax);
                
                UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0f);
                CGContextRef context = UIGraphicsGetCurrentContext();
                CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffff, 0.7f).CGColor);
                
                CGContextMoveToPoint(context, 0.0f, topLeftRadius);
                
                CGContextAddArcToPoint(context, 0.0f, 0.0f, topLeftRadius, 0.0f, topLeftRadius);
                CGContextAddLineToPoint(context, rect.size.width - topRightRadius, 0.0f);
                
                CGContextAddArcToPoint(context, rect.size.width, 0.0f, rect.size.width, topRightRadius, topRightRadius);
                CGContextAddLineToPoint(context, rect.size.width, rect.size.height - bottomRightRadius);
                
                CGContextAddArcToPoint(context, rect.size.width, rect.size.height, rect.size.width - bottomRightRadius, rect.size.height, bottomRightRadius);
                CGContextAddLineToPoint(context, bottomLeftRadius, rect.size.height);
                
                CGContextAddArcToPoint(context, 0.0f, rect.size.height, 0.0f, rect.size.height - bottomLeftRadius, bottomLeftRadius);
                CGContextAddLineToPoint(context, 0.0f, topLeftRadius);
                
                CGContextClosePath(context);
                CGContextFillPath(context);
                
                UIImage *highlightImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(topMax, leftMax, bottomMax, rightMax) resizingMode:UIImageResizingModeStretch];
                UIGraphicsEndImageContext();
                
                _temporaryHighlightView = [[UIImageView alloc] initWithImage:highlightImage];
                _temporaryHighlightView.frame = CGRectInset([_imageModel boundView].frame, inset, inset);
                [[_imageModel boundView].superview addSubview:_temporaryHighlightView];
            }
        }
        else if (_temporaryHighlightView != nil)
        {
            UIImageView *temporaryView = _temporaryHighlightView;
            [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^
            {
                temporaryView.alpha = 0.0f;
            } completion:^(__unused BOOL finished)
            {
                [temporaryView removeFromSuperview];
                
                if (_temporaryHighlightView == temporaryView)
                    _temporaryHighlightView = nil;
            }];
        }
    }
}

- (TGModernImageViewModel *)unsentButtonModel
{
    if (_unsentButtonModel == nil)
    {
        static UIImage *image = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            image = TGImageNamed(@"ModernMessageUnsentButton.png");
        });
        
        _unsentButtonModel = [[TGModernImageViewModel alloc] initWithImage:image];
        _unsentButtonModel.frame = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
        _unsentButtonModel.extendedEdges = UIEdgeInsetsMake(6, 6, 6, 6);
        
        _unsentButtonModel.hidden = !(_positionFlags == TGMessageGroupPositionNone || (_positionFlags & TGMessageGroupPositionTop && _positionFlags & TGMessageGroupPositionLeft));
    }
    
    return _unsentButtonModel;
}

- (void)updateMediaAvailability:(bool)mediaIsAvailable viewStorage:(TGModernViewStorage *)__unused viewStorage delayDisplay:(bool)delayDisplay
{
    _mediaIsAvailable = mediaIsAvailable;
    
    if (mediaIsAvailable || !delayDisplay) {
        [self updateImageOverlay:false];
    }
}

- (void)updateTimestampVisibility:(bool (^)(int32_t))visibilityTest alwaysAnimated:(bool)alwaysAnimated
{
    if (_positionFlags & TGMessageGroupPositionBottom && _positionFlags & TGMessageGroupPositionRight)
    {
        bool currentVisible = visibilityTest(_mid);
        
        int32_t previousMid = _message.mid - 1;
        TGMessageGroupPositionFlags previousFlags = [_groupedLayout positionForMessageId:previousMid];
        bool previousVisible = previousMid != 0 && (previousFlags & TGMessageGroupPositionBottom) ? visibilityTest(previousMid) : true;
        
        int32_t beforePreviousMid = _message.mid - 2;
        TGMessageGroupPositionFlags beforePreviousFlags = [_groupedLayout positionForMessageId:beforePreviousMid];
        bool beforePreviousVisible = beforePreviousMid != 0 && (beforePreviousFlags & TGMessageGroupPositionBottom) ? visibilityTest(beforePreviousMid) : true;
        
        bool timestampHidden = !currentVisible || !previousVisible || !beforePreviousVisible;
        [_imageModel setTimestampHidden:timestampHidden animated:alwaysAnimated || !timestampHidden];
    }
}

- (void)updateMediaVisibility
{
    _imageModel.mediaVisible = [_context isMediaVisibleInMessage:_mid];
    
    [self updateTimestampVisibility:^bool(int32_t mid) {
        return [_context isMediaVisibleInMessage:mid];
    } alwaysAnimated:false];
}

- (void)updateMessageFocus
{
    [self updateTimestampVisibility:^bool(int32_t mid) {
        return ![_context isFocusedOnMessage:mid];
    } alwaysAnimated:false];
}

- (NSString *)timestampString {
    NSString *dateText = nil;
    if (debugShowMessageIds)
        dateText = [[NSString alloc] initWithFormat:@"%d", _mid];
    else
        dateText = [TGDateUtils stringForShortTime:_date];
    return dateText;
}

- (void)updateMessage:(TGMessage *)message viewStorage:(TGModernViewStorage *)viewStorage sizeUpdated:(bool *)sizeUpdated
{
    [super updateMessage:message viewStorage:viewStorage sizeUpdated:sizeUpdated];
    
    NSString *previousCaption = _caption;
    NSString *currentCaption = nil;
    NSArray *currentTextCheckingResults = nil;
    
    for (id attachment in message.mediaAttachments) {
        if ([attachment isKindOfClass:[TGImageMediaAttachment class]]) {
            currentCaption = ((TGImageMediaAttachment *)attachment).caption;
            currentTextCheckingResults = ((TGImageMediaAttachment *)attachment).textCheckingResults;
        } else if ([attachment isKindOfClass:[TGVideoMediaAttachment class]]) {
            currentCaption = ((TGVideoMediaAttachment *)attachment).caption;
            currentTextCheckingResults = ((TGVideoMediaAttachment *)attachment).textCheckingResults;
        } else if ([attachment isKindOfClass:[TGDocumentMediaAttachment class]]) {
            currentCaption = ((TGDocumentMediaAttachment *)attachment).caption;
            currentTextCheckingResults = ((TGDocumentMediaAttachment *)attachment).textCheckingResults;
        }
    }
    
    if (_nextCaption)
    {
        currentCaption = _nextCaption;
        _nextCaption = nil;
    }
    
    bool previousEdited = _isEdited;
    if (message.isEdited && (_authorPeer == nil || ![_authorPeer isKindOfClass:[TGConversation class]] || !((TGConversation *)_authorPeer).isChannel || ((TGConversation *)_authorPeer).isChannelGroup)) {
        _isEdited = true;
    }
    
    if (!TGStringCompare(previousCaption, currentCaption) || previousEdited != _isEdited) {
        _caption = currentCaption;
        _textCheckingResults = currentTextCheckingResults;
        
        if (_positionFlags == TGMessageGroupPositionNone)
        {
            bool rebind = false;
            
            if (previousCaption.length == 0 && currentCaption.length != 0) {
                rebind = true;
            } else if (previousCaption.length != 0 && currentCaption.length == 0) {
                rebind = true;
            } else {
                _textModel.text = _caption;
                _textModel.textCheckingResults = currentTextCheckingResults;
                [_contentModel setNeedsSubmodelContentsUpdate];
            }
            
            *sizeUpdated = true;
            
            if (rebind) {
                UIView *container = _imageModel.boundView.superview;
                [self unbindView:viewStorage];
                
                [self setupContentModel:viewStorage];
                
                [self bindViewToContainer:container viewStorage:viewStorage];
                
                [_contentModel setNeedsSubmodelContentsUpdate];
                [_contentModel updateSubmodelContentsIfNeeded];
            } else if (_isEdited != previousEdited) {
                if (!_ignoreEditing && _isEdited) {
                    static CTFontRef dateFont = NULL;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^
                    {
                        if (iosMajorVersion() >= 7) {
                            dateFont = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGItalicSystemFontOfSize(11.0f) fontDescriptor], 0.0f, NULL);
                        } else {
                            UIFont *font = TGItalicSystemFontOfSize(11.0f);
                            dateFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
                        }
                    });
                    _editedLabelModel = [[TGModernLabelViewModel alloc] initWithText:TGLocalized(@"Conversation.MessageEditedLabel") textColor:_dateModel.textColor font:dateFont maxWidth:CGFLOAT_MAX];
                    [_contentModel addSubmodel:_editedLabelModel];
                }
            }
        }
    }
    
    _mid = message.mid;
    _groupedId = message.groupedId;
    TGMessageViewCountContentProperty *viewCount = _message.viewCount;
    if (message.viewCount != nil) {
        viewCount = message.viewCount;
    }
    if (viewCount != message.viewCount) {
        _message = [message copy];
        _message.viewCount = viewCount;
    } else {
        _message = message;
    }
    
    bool byAdmin = [_context isByAdmin:message];
    if (_byAdmin != byAdmin)
    {
        _byAdmin = byAdmin;
        
        if (_byAdmin)
        {
            CTFontRef adminFont = NULL;
            if (iosMajorVersion() >= 7) {
                adminFont = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGSystemFontOfSize(12.0f) fontDescriptor], 0.0f, NULL);
            } else {
                UIFont *font = TGSystemFontOfSize(12.0f);
                adminFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
            }
            
            if (_contentModel != nil)
            {
                _adminContentModel = [[TGModernFlatteningViewModel alloc] init];
                _adminContentModel.viewUserInteractionDisabled = true;
                [self insertSubmodel:_adminContentModel aboveSubmodel:_contentModel];
                [_adminContentModel bindViewToContainer:[_imageModel.boundView superview] viewStorage:viewStorage];
                
                _adminModel = [[TGModernTextViewModel alloc] initWithText:TGLocalized(@"Conversation.Admin") font:adminFont];
                _adminModel.textColor = UIColorRGB(0xb4b4b7);
                [_adminContentModel addSubmodel:_adminModel];
            }
        }
        else
        {
            [self removeSubmodel:_adminContentModel viewStorage:viewStorage];
            [self removeSubmodel:_adminModel viewStorage:viewStorage];
        }
        
        if (sizeUpdated) {
            *sizeUpdated = true;
        }
    }
    
    bool messageUnread = [_context isMessageUnread:message];
    
    if (_deliveryState != _message.deliveryState || (!_incoming && _read != !messageUnread) || (_messageViews != nil && _messageViews.viewCount != _message.viewCount.viewCount))
    {
        _messageViews = _message.viewCount;
        TGMessageViewModelLayoutConstants const *layoutConstants = TGGetMessageViewModelLayoutConstants();
        
        TGMessageDeliveryState previousDeliveryState = _deliveryState;
        _deliveryState = message.deliveryState;
        
        if (_messageViewsModel != nil) {
            _messageViewsModel.count = _message.viewCount.viewCount;
            _messageViewsModel.hidden = _deliveryState != TGMessageDeliveryStateDelivered;
        }
        
        bool previousRead = _read;
        _read = !messageUnread;
        
        bool hasCaption = _caption.length > 0 && _positionFlags == TGMessageGroupPositionNone;
        if (!hasCaption && _webPageFooterModel == nil)
        {
            [_imageModel setTimestampString:[self timestampString] signatureString:_authorSignature displayCheckmarks:!_incoming && !(_incomingAppearance && _context.isSavedMessages) && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:true];
            [_imageModel setDisplayTimestampProgress:_deliveryState == TGMessageDeliveryStatePending];
        }
        else
        {
            if (_date != (int32_t)message.date && !debugShowMessageIds)
            {
                _date = (int32_t)message.date;
                
                int daytimeVariant = 0;
                NSString *dateText = [TGDateUtils stringForShortTime:(int)message.date daytimeVariant:&daytimeVariant];
                [_dateModel setText:dateText daytimeVariant:daytimeVariant];
            }
        }
        
        if (_deliveryState == TGMessageDeliveryStateDelivered)
        {
            if (_caption.length > 0 || _webPageFooterModel != nil)
            {
                if (_progressModel != nil)
                {
                    [self removeSubmodel:_progressModel viewStorage:viewStorage];
                    _progressModel = nil;
                }
                
                _checkFirstModel.alpha = 1.0f;
                
                if (previousDeliveryState == TGMessageDeliveryStatePending && [_checkFirstModel boundView] != nil)
                {
                    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
                    animation.fromValue = @(1.3f);
                    animation.toValue = @(1.0f);
                    animation.duration = 0.1;
                    animation.removedOnCompletion = true;
                    
                    [[_checkFirstModel boundView].layer addAnimation:animation forKey:@"transform.scale"];
                }
                
                if (_read)
                {
                    _checkSecondModel.alpha = 1.0f;
                    
                    if (!previousRead && [_checkSecondModel boundView] != nil)
                    {
                        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
                        animation.fromValue = @(1.3f);
                        animation.toValue = @(1.0f);
                        animation.duration = 0.1;
                        animation.removedOnCompletion = true;
                        
                        [[_checkSecondModel boundView].layer addAnimation:animation forKey:@"transform.scale"];
                    }
                }
            }
            
            if (_unsentButtonModel != nil)
            {
                [self removeSubmodel:_unsentButtonModel viewStorage:viewStorage];
                _unsentButtonModel = nil;
            }
        }
        else if (_deliveryState == TGMessageDeliveryStateFailed)
        {
            if (_caption.length > 0 || _webPageFooterModel != nil)
            {
                if (_progressModel != nil)
                {
                    [self removeSubmodel:_progressModel viewStorage:viewStorage];
                    _progressModel = nil;
                }
                
                if (_checkFirstModel != nil)
                {
                    if (_checkFirstEmbeddedInContent)
                    {
                        [_contentModel removeSubmodel:_checkFirstModel viewStorage:viewStorage];
                        [_contentModel setNeedsSubmodelContentsUpdate];
                    }
                    else
                        [self removeSubmodel:_checkFirstModel viewStorage:viewStorage];
                }
                
                if (_checkSecondModel != nil)
                {
                    if (_checkSecondEmbeddedInContent)
                    {
                        [_contentModel removeSubmodel:_checkSecondModel viewStorage:viewStorage];
                        [_contentModel setNeedsSubmodelContentsUpdate];
                    }
                    else
                        [self removeSubmodel:_checkSecondModel viewStorage:viewStorage];
                }
            }
            
            if (_unsentButtonModel == nil)
            {
                [self addSubmodel:[self unsentButtonModel]];
                if ([_imageModel boundView] != nil)
                    [_unsentButtonModel bindViewToContainer:[_imageModel boundView].superview viewStorage:viewStorage];
                _unsentButtonModel.frame = CGRectOffset(_unsentButtonModel.frame, self.frame.size.width + _unsentButtonModel.frame.size.width, self.frame.size.height - _unsentButtonModel.frame.size.height - ((_collapseFlags & TGModernConversationItemCollapseBottom) ? 5 : 6));
                
                _unsentButtonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unsentButtonTapGesture:)];
                [[_unsentButtonModel boundView] addGestureRecognizer:_unsentButtonTapRecognizer];
            }
            
            if (self.frame.size.width > FLT_EPSILON)
            {
                if ([_imageModel boundView] != nil)
                {
                    [UIView animateWithDuration:0.2 animations:^
                    {
                        [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
                    }];
                }
                else
                    [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
            }
        }
        else if (_deliveryState == TGMessageDeliveryStatePending)
        {
            if (_caption.length > 0 || _webPageFooterModel != nil)
            {
                if (_progressModel == nil)
                {
                    CGFloat unsentOffset = 0.0f;
                    if (!_incoming && previousDeliveryState == TGMessageDeliveryStateFailed)
                        unsentOffset = 29.0f;
                    
                    _progressModel = [[TGModernClockProgressViewModel alloc] initWithType:_incomingAppearance ? TGModernClockProgressTypeIncomingClock : TGModernClockProgressTypeOutgoingClock];
                    _progressModel.frame = CGRectMake(self.frame.size.width - 28 - layoutConstants->rightInset - unsentOffset, _contentModel.frame.origin.y + _contentModel.frame.size.height - 17 + 1.0f, 15, 15);
                    [self addSubmodel:_progressModel];
                    
                    if ([_contentModel boundView] != nil)
                    {
                        [_progressModel bindViewToContainer:[_contentModel boundView].superview viewStorage:viewStorage];
                    }
                }
                
                [_contentModel removeSubmodel:_checkFirstModel viewStorage:viewStorage];
                [_contentModel removeSubmodel:_checkSecondModel viewStorage:viewStorage];
                _checkFirstEmbeddedInContent = false;
                _checkSecondEmbeddedInContent = false;
                
                if (![self containsSubmodel:_checkFirstModel] && !_incomingAppearance)
                {
                    [self addSubmodel:_checkFirstModel];
                    
                    if ([_contentModel boundView] != nil)
                        [_checkFirstModel bindViewToContainer:[_contentModel boundView].superview viewStorage:viewStorage];
                }
                if (![self containsSubmodel:_checkSecondModel] && !_incomingAppearance)
                {
                    [self addSubmodel:_checkSecondModel];
                    
                    if ([_contentModel boundView] != nil)
                        [_checkSecondModel bindViewToContainer:[_contentModel boundView].superview viewStorage:viewStorage];
                }
                
                _checkFirstModel.alpha = 0.0f;
                _checkSecondModel.alpha = 0.0f;
            }
            
            if (_unsentButtonModel != nil)
            {
                UIView<TGModernView> *unsentView = [_unsentButtonModel boundView];
                if (unsentView != nil)
                {
                    [unsentView removeGestureRecognizer:_unsentButtonTapRecognizer];
                    _unsentButtonTapRecognizer = nil;
                }
                
                if (unsentView != nil)
                {
                    [viewStorage allowResurrectionForOperations:^
                    {
                        [self removeSubmodel:_unsentButtonModel viewStorage:viewStorage];
                        
                        UIView *restoredView = [viewStorage dequeueViewWithIdentifier:[unsentView viewIdentifier] viewStateIdentifier:[unsentView viewStateIdentifier]];
                        
                        if (restoredView != nil)
                        {
                            [[_imageModel boundView].superview addSubview:restoredView];
                            
                            [UIView animateWithDuration:0.2 animations:^
                            {
                                restoredView.frame = CGRectOffset(restoredView.frame, restoredView.frame.size.width + 9, 0.0f);
                                restoredView.alpha = 0.0f;
                            } completion:^(__unused BOOL finished)
                            {
                                [viewStorage enqueueView:restoredView];
                            }];
                        }
                    }];
                }
                else
                    [self removeSubmodel:_unsentButtonModel viewStorage:viewStorage];
                
                _unsentButtonModel = nil;
            }
            
            if (self.frame.size.width > FLT_EPSILON)
            {
                if ([_imageModel boundView] != nil)
                {
                    [UIView animateWithDuration:0.2 animations:^
                    {
                        [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
                    }];
                }
                else
                    [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
            }
        }
        
        if ((previousCaption.length == 0) != (_caption.length == 0)) {
            [self updateImageUri:_currentBaseUri];
        }
    }
    
    bool isMainModel = [self hasMainPosition];
    _actionButtonModel.hidden = _message.local || (_positionFlags != TGMessageGroupPositionNone && !isMainModel);
    
    TGBotReplyMarkup *replyMarkup = message.replyMarkup != nil && message.replyMarkup.isInline ? message.replyMarkup : nil;
    if (!TGObjectCompare(_replyMarkup, replyMarkup)) {
        _replyMarkup = replyMarkup;
        
        if (_replyButtonsModel == nil) {
            _replyButtonsModel = [[TGMessageReplyButtonsModel alloc] init];
            __weak TGImageMessageViewModel *weakSelf = self;
            _replyButtonsModel.buttonActivated = ^(TGBotReplyMarkupButton *button, NSInteger index) {
                __strong TGImageMessageViewModel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{@"mid": @(strongSelf->_mid), @"command": button.text}];
                    if (button.action != nil) {
                        dict[@"action"] = button.action;
                    }
                    dict[@"index"] = @(index);
                    [strongSelf->_context.companionHandle requestAction:@"activateCommand" options:dict];
                }
            };
            
            [self addSubmodel:_replyButtonsModel];
        }
        if (_imageModel.boundView != nil) {
            [_replyButtonsModel unbindView:viewStorage];
            [_replyButtonsModel setReplyMarkup:replyMarkup hasReceipt:false];
            [_replyButtonsModel bindViewToContainer:_imageModel.boundView.superview viewStorage:viewStorage];
        } else {
            [_replyButtonsModel setReplyMarkup:replyMarkup hasReceipt:false];
        }
        if (sizeUpdated) {
            *sizeUpdated = true;
        }
    }
}

- (void)dealloc {
    [_callbackButtonInProgressDisposable dispose];
}

- (void)_maybeRestructureStateModels:(TGModernViewStorage *)viewStorage
{
    if (!_incoming && [_contentModel boundView] == nil && !_incomingAppearance)
    {
        if (_deliveryState == TGMessageDeliveryStateDelivered)
        {
            if (!_checkFirstEmbeddedInContent)
            {
                if ([self.submodels containsObject:_checkFirstModel])
                {
                    _checkFirstEmbeddedInContent = true;
                    
                    [self removeSubmodel:_checkFirstModel viewStorage:viewStorage];
                    _checkFirstModel.frame = CGRectOffset(_checkFirstModel.frame, -_contentModel.frame.origin.x, -_contentModel.frame.origin.y);
                    [_contentModel addSubmodel:_checkFirstModel];
                }
            }
            
            if (_read && !_checkSecondEmbeddedInContent)
            {
                if ([self.submodels containsObject:_checkSecondModel])
                {
                    _checkSecondEmbeddedInContent = true;
                    
                    [self removeSubmodel:_checkSecondModel viewStorage:viewStorage];
                    _checkSecondModel.frame = CGRectOffset(_checkSecondModel.frame, -_contentModel.frame.origin.x, -_contentModel.frame.origin.y);
                    [_contentModel addSubmodel:_checkSecondModel];
                }
            }
        }
    }
}

- (void)updateProgress:(bool)progressVisible progress:(float)progress viewStorage:(TGModernViewStorage *)__unused viewStorage animated:(bool)animated
{
    [super updateProgress:progressVisible progress:progress viewStorage:viewStorage animated:animated];
    
    bool progressWasVisible = _progressVisible;
    float previousProgress = _progress;
    
    _progress = progress;
    _progressVisible = progressVisible;
    
    bool finalAnimated = ((progressWasVisible && !_progressVisible) || (_progressVisible && ABS(_progress - previousProgress) > FLT_EPSILON)) && animated;
    if (_positionFlags != TGMessageGroupPositionNone && [_message local] && _progress >= 1.0f - FLT_EPSILON)
        finalAnimated = animated;
    
    [self updateImageOverlay:finalAnimated];
}

- (void)updateMessageAttributes
{
    [super updateMessageAttributes];
    
    bool previousRead = _read;
    _read = ![_context isMessageUnread:_message];
    if (previousRead != _read) {
        if (_checkSecondModel != nil) {
            _checkSecondModel.alpha = 1.0f;
            
            if (!previousRead && [_checkSecondModel boundView] != nil) {
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
                animation.fromValue = @(1.3f);
                animation.toValue = @(1.0f);
                animation.duration = 0.1;
                animation.removedOnCompletion = true;
                
                [[_checkSecondModel boundView].layer addAnimation:animation forKey:@"transform.scale"];
            }
        } else {
            [_imageModel setTimestampString:[self timestampString] signatureString:_authorSignature displayCheckmarks:!_incoming && !(_incomingAppearance && _context.isSavedMessages) && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:true];
        }
    }
    
    if (self.isSecret)
    {
        bool isMessageViewed = [_context isSecretMessageViewed:_mid];
        NSTimeInterval messageViewDate = [_context secretMessageViewDate:_mid];
        
        if (_isMessageViewed != isMessageViewed || ABS(_messageViewDate - messageViewDate) > DBL_EPSILON)
        {
            _isMessageViewed = isMessageViewed;
            _messageViewDate = messageViewDate;
            
            [self updateImageOverlay:false];
            
            if (_incoming && ABS(_messageViewDate) > DBL_EPSILON)
                [self _updateViewDateTimerIfVisible];
        }
    }
}

- (void)_updateViewDateTimerIfVisible
{
    [_viewDateTimer invalidate];
    _viewDateTimer = nil;
    
    if (_isMessageViewed && _incoming && ABS(_messageViewDate) > DBL_EPSILON && _imageModel.boundView != nil)
    {
        [_imageModel setAdditionalDataString:[self defaultAdditionalDataString]];
        [self updateImageOverlay:true];
        
        _viewDateTimer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(_updateViewDateTimerIfVisible) interval:0.5 repeat:false runLoopModes:NSRunLoopCommonModes];
    }
}

- (void)_invalidateViewDateTimer
{
    [_viewDateTimer invalidate];
    _viewDateTimer = nil;
}

- (void)updateImageOverlay:(bool)animated
{
    _instantPreviewTouchAreaModel.viewUserInteractionDisabled = !_mediaIsAvailable || _progressVisible;
    
    if (_progressVisible)
    {
        if (_positionFlags != TGMessageGroupPositionNone && [_message local] && _progress >= 1.0f - FLT_EPSILON)
        {
            [_imageModel setOverlayType:TGMessageImageViewOverlayCompleted animated:animated];
        }
        else
        {                
            [_imageModel setOverlayType:TGMessageImageViewOverlayProgress animated:false];
            [_imageModel setProgress:_progress animated:animated];
        }
    }
    else if (!_mediaIsAvailable)
    {
        if (_canDownload) {
            [_imageModel setOverlayType:TGMessageImageViewOverlayDownload animated:false];
        } else {
            [_imageModel setOverlayType:TGMessageImageViewOverlayNone animated:false];
        }
        [_imageModel setProgress:0.0f animated:false];
    }
    else
    {
        if (self.isSecret && _isMessageViewed && _incoming && ABS(_messageViewDate) > DBL_EPSILON)
        {
            NSTimeInterval endTime = _messageViewDate + _messageLifetime;
            int remainingSeconds = MAX(0, (int)(endTime - CFAbsoluteTimeGetCurrent()));
            
            [_imageModel setSecretProgress:(CGFloat)remainingSeconds / (CGFloat)_messageLifetime completeDuration:_messageLifetime animated:animated];
            [_imageModel setOverlayType:TGMessageImageViewOverlaySecretProgress];
        }
        else
            [_imageModel setOverlayType:[self defaultOverlayActionType] animated:animated];
    }
}

- (void)imageDataInvalidated:(NSString *)imageUrl
{
    if ([_legacyThumbnailCacheUri isEqualToString:imageUrl])
    {
        [_imageModel reloadImage:false];
    }
}

- (void)bindSpecialViewsToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage atItemPosition:(CGPoint)itemPosition
{
    _boundOffset = itemPosition;
    
    [_backgroundModel bindViewToContainer:container viewStorage:viewStorage];
    [_backgroundModel boundView].frame = CGRectOffset([_backgroundModel boundView].frame, itemPosition.x, itemPosition.y);
    
    [super bindSpecialViewsToContainer:container viewStorage:viewStorage atItemPosition:itemPosition];
    
    [_imageModel bindViewToContainer:container viewStorage:viewStorage];
    [_imageModel boundView].frame = CGRectOffset([_imageModel boundView].frame, itemPosition.x, itemPosition.y);
    ((TGMessageImageViewContainer *)[_imageModel boundView]).imageView.delegate = self;
    
    [_replyHeaderModel bindSpecialViewsToContainer:container viewStorage:viewStorage atItemPosition:CGPointMake(itemPosition.x + _contentModel.frame.origin.x + _replyHeaderModel.frame.origin.x, itemPosition.y + _contentModel.frame.origin.y + _replyHeaderModel.frame.origin.y)];
    
    [_replyButtonsModel bindSpecialViewsToContainer:container viewStorage:viewStorage atItemPosition:CGPointMake(itemPosition.x, itemPosition.y)];
    [self subscribeToCallbackButtonInProgress];
}

- (void)subscribeToCallbackButtonInProgress {
    if (_replyButtonsModel != nil) {
        __weak TGImageMessageViewModel *weakSelf = self;
        [_callbackButtonInProgressDisposable setDisposable:[[[_context callbackInProgress] deliverOn:[SQueue mainQueue]] startWithNext:^(NSDictionary *next) {
            __strong TGImageMessageViewModel *strongSelf = weakSelf;
            if (strongSelf != nil) {
                if (next != nil) {
                    if ([next[@"mid"] intValue] == strongSelf->_mid) {
                        [strongSelf->_replyButtonsModel setButtonIndexInProgress:[next[@"buttonIndex"] intValue]];
                    } else {
                        [strongSelf->_replyButtonsModel setButtonIndexInProgress:NSNotFound];
                    }
                } else {
                    [strongSelf->_replyButtonsModel setButtonIndexInProgress:NSNotFound];
                }
            }
        }]];
    }
}

- (CGRect)effectiveContentFrame
{
    if (_backgroundModel != nil && _positionFlags == TGMessageGroupPositionNone)
        return _backgroundModel.frame;
    
    return _imageModel.frame;
}

- (CGRect)fullContentFrame
{
    if (_backgroundModel != nil)
        return _backgroundModel.frame;
    
    return _imageModel.frame;
}

- (UIView *)referenceViewForImageTransition
{
    return [_imageModel boundView];
}

- (void)bindViewToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage
{
    _boundOffset = CGPointZero;
    
    _boundToContainer = true;
    
    [self _maybeRestructureStateModels:viewStorage];
    
    [self updateEditingState:nil viewStorage:nil animationDelay:-1.0];
    
    [super bindViewToContainer:container viewStorage:viewStorage];
    
    [_replyHeaderModel bindSpecialViewsToContainer:_contentModel.boundView viewStorage:viewStorage atItemPosition:CGPointMake(_replyHeaderModel.frame.origin.x, _replyHeaderModel.frame.origin.y)];
    
    _boundDoubleTapRecognizer = [[TGDoubleTapGestureRecognizer alloc] initWithTarget:self action:@selector(messageDoubleTapGesture:)];
    _boundDoubleTapRecognizer.delegate = self;
    [[_imageModel boundView] addGestureRecognizer:_boundDoubleTapRecognizer];
    
    if (_backgroundModel != nil)
    {
        _boundBackgroundDoubleTapRecognizer = [[TGDoubleTapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundDoubleTapGesture:)];
        _boundBackgroundDoubleTapRecognizer.delegate = self;
        [[_backgroundModel boundView] addGestureRecognizer:_boundBackgroundDoubleTapRecognizer];
    }
    
    if (_unsentButtonModel != nil)
    {
        _unsentButtonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unsentButtonTapGesture:)];
        [[_unsentButtonModel boundView] addGestureRecognizer:_unsentButtonTapRecognizer];
    }
    
    _imageModel.mediaVisible = [_context isMediaVisibleInMessage:_mid];
    [_imageModel setOverlayDiameter:_positionFlags != TGMessageGroupPositionNone ? 32.0f : 50.0f];
    
    ((TGMessageImageViewContainer *)[_imageModel boundView]).imageView.delegate = self;
    
    [self _updateViewDateTimerIfVisible];
    
    if (_actionButtonModel != nil) {
        [(TGModernButtonView *)_actionButtonModel.boundView addTarget:self action:@selector(actionPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [(UIButton *)[_groupCheckAreaModel boundView] addTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [(UIButton *)[_groupCheckButtonModel boundView] addTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self subscribeToCallbackButtonInProgress];
}

- (void)unbindView:(TGModernViewStorage *)viewStorage
{
    [self clearLinkSelection];
    
    _boundToContainer = false;
    
    _boundOffset = CGPointZero;
    
    [[_imageModel boundView] removeGestureRecognizer:_boundDoubleTapRecognizer];
    _boundDoubleTapRecognizer.delegate = nil;
    _boundDoubleTapRecognizer = nil;
    
    ((TGMessageImageViewContainer *)[_imageModel boundView]).imageView.delegate = self;
    
    if (_backgroundModel != nil)
    {
        [[_backgroundModel boundView] removeGestureRecognizer:_boundBackgroundDoubleTapRecognizer];
        _boundBackgroundDoubleTapRecognizer.delegate = nil;
        _boundBackgroundDoubleTapRecognizer = nil;
    }
    
    if (_temporaryHighlightView != nil)
    {
        [_temporaryHighlightView removeFromSuperview];
        _temporaryHighlightView = nil;
    }
    
    if (_unsentButtonModel != nil)
    {
        [[_unsentButtonModel boundView] removeGestureRecognizer:_unsentButtonTapRecognizer];
        _unsentButtonTapRecognizer = nil;
    }
    
    [self _invalidateViewDateTimer];
    
    if (_actionButtonModel != nil)
    {
        [(TGModernButtonView *)_actionButtonModel.boundView removeTarget:self action:@selector(actionPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [(UIButton *)[_groupCheckAreaModel boundView] removeTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [(UIButton *)[_groupCheckButtonModel boundView] removeTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    
    [super unbindView:viewStorage];
    
    [_callbackButtonInProgressDisposable setDisposable:nil];
}

- (void)messageDoubleTapGesture:(TGDoubleTapGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan)
    {
        [self clearLinkSelection];
    }
    
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        if ([self instantPreviewGesture])
        {
            [_context.companionHandle requestAction:@"closeMediaRequested" options:@{@"mid": @(_mid)}];
        }
        else
        {
            if (recognizer.longTapped)
            {
                [_context.companionHandle requestAction:@"messageSelectionRequested" options:@{@"mid": @(_mid)}];
            }
            else
            {
                if (_mediaIsAvailable)
                {
                    [self activateMedia:[self isInstant]];
                }
                else
                    [_context.companionHandle requestAction:@"mediaDownloadRequested" options:@{@"mid": @(_mid)}];
            }
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateCancelled)
    {
        [_context.companionHandle requestAction:@"closeMediaRequested" options:@{@"mid": @(_mid)}];
    }
}

- (void)backgroundDoubleTapGesture:(TGDoubleTapGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan)
    {
        [self clearLinkSelection];
    }
    
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint point = [recognizer locationInView:[_contentModel boundView]];
        NSString *linkCandidate = [_textModel linkAtPoint:CGPointMake(point.x - _textModel.frame.origin.x, point.y - _textModel.frame.origin.y) regionData:NULL];
        
        bool insideBackground = [self insideBackground:[recognizer locationInView:recognizer.view]];
        
        if (recognizer.longTapped)
        {
            if (linkCandidate != nil)
                [_context.companionHandle requestAction:@"openLinkWithOptionsRequested" options:@{@"url": linkCandidate}];
            else if (_positionFlags != TGMessageGroupPositionNone && insideBackground)
                [_context.companionHandle requestAction:@"messageSelectionRequested" options:@{@"mid": @(_mid), @"groupedId": @(_message.groupedId)}];
            else
                [_context.companionHandle requestAction:@"messageSelectionRequested" options:@{@"mid": @(_mid)}];
        }
        else if (recognizer.doubleTapped)
        {
            if (_positionFlags != TGMessageGroupPositionNone && insideBackground)
                [_context.companionHandle requestAction:@"messageSelectionRequested" options:@{@"mid": @(_mid), @"groupedId": @(_message.groupedId)}];
            else
                [_context.companionHandle requestAction:@"messageSelectionRequested" options:@{@"mid": @(_mid)}];
        }
        else if (linkCandidate != nil)
            [_context.companionHandle requestAction:@"openLinkRequested" options:@{@"url": linkCandidate, @"mid": @(_mid)}];
        else if (_replyHeaderModel && CGRectContainsPoint(_replyHeaderModel.frame, point))
            [_context.companionHandle requestAction:@"navigateToMessage" options:@{@"mid": @(_replyMessageId), @"sourceMid": @(_mid)}];
        else if (_viaUserModel != nil && CGRectContainsPoint(_viaUserModel.frame, point)) {
            [_context.companionHandle requestAction:@"useContextBot" options:@{@"uid": @((int32_t)_viaUser.uid), @"username": _viaUser.userName == nil ? @"" : _viaUser.userName}];
        }
        else if (_forwardedHeaderModel && CGRectContainsPoint(_forwardedHeaderModel.frame, point)) {
            if (_viaUser != nil && [_forwardedHeaderModel linkAtPoint:CGPointMake(point.x - _forwardedHeaderModel.frame.origin.x, point.y - _forwardedHeaderModel.frame.origin.y) regionData:NULL]) {
                [_context.companionHandle requestAction:@"useContextBot" options:@{@"uid": @((int32_t)_viaUser.uid), @"username": _viaUser.userName == nil ? @"" : _viaUser.userName}];
            } else {
                if (TGPeerIdIsChannel(_forwardedPeerId)) {
                    [_context.companionHandle requestAction:@"peerAvatarTapped" options:@{@"peerId": @(_forwardedPeerId), @"messageId": @(_forwardedMessageId)}];
                } else {
                    [_context.companionHandle requestAction:@"userAvatarTapped" options:@{@"uid": @((int32_t)_forwardedPeerId)}];
                }
            }
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        return [super gestureRecognizerShouldBegin:gestureRecognizer];
    
    UIView *imageView = ((TGMessageImageViewContainer *)[_imageModel boundView]).imageView;
    if (imageView != nil)
    {
        UIView *hitTestResult = [imageView hitTest:[gestureRecognizer locationInView:imageView] withEvent:nil];
        if ([hitTestResult isKindOfClass:[UIControl class]])
            return false;
        
        return true;
    }
    
    return false;
}

- (void)unsentButtonTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        [_context.companionHandle requestAction:@"showUnsentMessageMenu" options:@{@"mid": @(_mid)}];
    }
}

- (void)messageImageViewActionButtonPressed:(TGMessageImageView *)messageImageView withAction:(TGMessageImageViewActionType)action
{
    if (messageImageView == ((TGMessageImageViewContainer *)[_imageModel boundView]).imageView)
    {
        if (action == TGMessageImageViewActionCancelDownload)
            [self cancelMediaDownload];
        else
            [self actionButtonPressed];
    }
}

- (void)actionButtonPressed
{
    if (_mediaIsAvailable)
    {
        if (![self instantPreviewGesture])
        {
            [self activateMedia:[self isInstant]];
        }
    }
    else
        [_context.companionHandle requestAction:@"mediaDownloadRequested" options:@{@"mid": @(_mid)}];
}

- (void)activateMedia
{
    [self activateMedia:false];
}

- (void)activateMedia:(bool)instant
{
    if (_previewEnabled)
        [_context.companionHandle requestAction:@"openMediaRequested" options:@{@"mid": @(_mid), @"instant": @(instant)}];
}

- (void)deactivateMedia:(bool)instant
{
    [_context.companionHandle requestAction:@"closeMediaRequested" options:@{@"mid": @(_mid), @"instant": @(instant)}];
}

- (void)cancelMediaDownload
{
    [_context.companionHandle requestAction:@"mediaProgressCancelRequested" options:@{@"mid": @(_mid)}];
}

- (bool)gestureRecognizerShouldHandleLongTap:(TGDoubleTapGestureRecognizer *)recognizer
{
    if (recognizer == _boundDoubleTapRecognizer)
        return ![self instantPreviewGesture];
    
    return true;
}

- (void)gestureRecognizer:(TGDoubleTapGestureRecognizer *)recognizer didBeginAtPoint:(CGPoint)point
{
    if (recognizer == _boundBackgroundDoubleTapRecognizer)
        [self updateLinkSelection:point];
}

- (void)gestureRecognizerDidFail:(TGDoubleTapGestureRecognizer *)__unused recognizer
{
    [self clearLinkSelection];
}

- (int)gestureRecognizer:(TGDoubleTapGestureRecognizer *)recognizer shouldFailTap:(CGPoint)__unused point
{
    if (recognizer == _boundDoubleTapRecognizer)
        return 3;
    
    if (recognizer == _boundBackgroundDoubleTapRecognizer)
    {
        CGPoint convertedPoint = [recognizer locationInView:[_contentModel boundView]];
        if (([_textModel linkAtPoint:CGPointMake(convertedPoint.x - _textModel.frame.origin.x, convertedPoint.y - _textModel.frame.origin.y) regionData:NULL] != nil || (_replyHeaderModel && CGRectContainsPoint(_replyHeaderModel.frame, convertedPoint)) || (_forwardedHeaderModel && CGRectContainsPoint(_forwardedHeaderModel.frame, convertedPoint)) ||
             (_viaUserModel && CGRectContainsPoint(_viaUserModel.frame, convertedPoint))))
            return 3;
    }

    return 0;
}

- (void)doubleTapGestureRecognizerSingleTapped:(TGDoubleTapGestureRecognizer *)__unused recognizer
{
}

- (bool)gestureRecognizerShouldLetScrollViewStealTouches:(TGDoubleTapGestureRecognizer *)__unused recognizer
{
    return true;
}

- (bool)gestureRecognizerShouldFailOnMove:(TGDoubleTapGestureRecognizer *)recognizer
{
    if (recognizer == _boundDoubleTapRecognizer)
        return ![self instantPreviewGesture];
        
    return true;
}

- (void)setCollapseFlags:(int)collapseFlags
{
    if (_collapseFlags != collapseFlags)
    {
        _collapseFlags = collapseFlags;
        if (!(collapseFlags & TGModernConversationItemCollapseBottom) && [_authorPeer isKindOfClass:[TGConversation class]]) {
            [_backgroundModel setPartialMode:false];
        } else {
            [_backgroundModel setPartialMode:collapseFlags & TGModernConversationItemCollapseBottom];
        }
    }
}

- (bool)hasMainPosition
{
    return (_positionFlags & TGMessageGroupPositionLeft && _positionFlags & TGMessageGroupPositionTop);
}

- (void)setPositionFlags:(int)positionFlags
{
    int previousFlags = _positionFlags;
    if (_positionFlags != positionFlags)
    {
        _positionFlags = positionFlags;
        
        if (_backgroundModel != nil || (positionFlags != TGMessageGroupPositionNone && !(positionFlags & TGMessageGroupPositionBottom && positionFlags & TGMessageGroupPositionRight)))
            _imageModel.timestampHidden = true;
        else
            _imageModel.timestampHidden = false;
        
        _editingCheckButtonGrowTransition = positionFlags != TGMessageGroupPositionNone;
        [_imageModel setTimestampUnlimitedWidth:(positionFlags & TGMessageGroupPositionBottom && positionFlags & TGMessageGroupPositionRight)];
        
        bool isMainModel = [self hasMainPosition];
        _avatarModel.hidden = (positionFlags != TGMessageGroupPositionNone && !isMainModel);
        _actionButtonModel.hidden = _message.local || (positionFlags != TGMessageGroupPositionNone && !isMainModel);
        _unsentButtonModel.hidden = !(_positionFlags == TGMessageGroupPositionNone || (_positionFlags & TGMessageGroupPositionTop && _positionFlags & TGMessageGroupPositionLeft));
        
        bool hadNoPosition = previousFlags == TGMessageGroupPositionNone || previousFlags == TGMessageGroupPositionUnknown;
        bool switchingToNoPosition = positionFlags == TGMessageGroupPositionNone;
        bool changingPosition = (previousFlags != TGMessageGroupPositionNone && positionFlags != TGMessageGroupPositionNone);
        if (hadNoPosition || switchingToNoPosition || changingPosition)
        {
            TGModernViewStorage *viewStorage = [[TGModernViewStorage alloc] init];
            UIView *container = _imageModel.boundView.superview;
            [self unbindView:viewStorage];
            
            bool hadContentModel = _contentModel;
            [self setupContentModel:viewStorage];
            if (_contentModel != nil)
            {
                [_contentModel setNeedsSubmodelContentsUpdate];
                if (!hadContentModel || (previousFlags != TGMessageGroupPositionNone && _positionFlags == TGMessageGroupPositionNone))
                    _skipContentModelAnimation = true;
            }
            if (container != nil)
                [self bindViewToContainer:container viewStorage:viewStorage];
        }
    }
    
    [_imageModel setOverlayDiameter:positionFlags != TGMessageGroupPositionNone ? 32.0f : 50.0f];
}

- (void)setGroupedLayout:(TGMessageGroupedLayout *)groupedLayout
{
    _groupedLayout = groupedLayout;
    
    TGMessageGroupPositionFlags position = [groupedLayout positionForMessageId:_message.mid];
    if (_positionFlags == position && (position & TGMessageGroupPositionTop && position & TGMessageGroupPositionLeft) && _contentModel != nil)
    {
        if (self.frame.size.width > FLT_EPSILON)
            [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
    }
}

- (CGSize)contentSizeForContainerSize:(CGSize)containerSize needsContentsUpdate:(bool *)needsContentsUpdate infoWidth:(CGFloat)infoWidth {
    int layoutFlags = TGReusableLabelLayoutMultiline | TGReusableLabelLayoutHighlightLinks;
    
    if (_context.commandsEnabled || _isBot)
        layoutFlags |= TGReusableLabelLayoutHighlightCommands;
    
    bool updateContents = [_textModel layoutNeedsUpdatingForContainerSize:containerSize additionalTrailingWidth:_webPageFooterModel == nil ? infoWidth : 0.0f layoutFlags:layoutFlags];
    _textModel.layoutFlags = layoutFlags;
    _textModel.additionalTrailingWidth = infoWidth;
    if (updateContents)
        [_textModel layoutForContainerSize:containerSize];
    
    if (needsContentsUpdate != NULL)
        *needsContentsUpdate = updateContents;
    
    CGSize size = _textModel.frame.size;
    
    if (_webPageFooterModel != nil) {
        CGSize webpageSize = [_webPageFooterModel contentSizeForContainerSize:containerSize contentSize:containerSize infoWidth:infoWidth needsContentsUpdate:needsContentsUpdate];
        size.height += webpageSize.height;
        if (_caption.length == 0) {
            size.height -= 19.0f;
        }
    }
    
    return size;
}

- (bool)hasHeader
{
    return (_positionFlags == TGMessageGroupPositionNone && (_replyHeaderModel != nil || _forwardedHeaderModel)) || (_positionFlags != TGMessageGroupPositionNone && (_replyHeader != nil || (_forwardPeer != nil && !_context.isSavedMessages)));
}

- (void)layoutForContainerSize:(CGSize)containerSize
{
    bool isPost = _authorPeer != nil && [_authorPeer isKindOfClass:[TGConversation class]];
    
    TGMessageViewModelLayoutConstants const *layoutConstants = TGGetMessageViewModelLayoutConstants();
    
    CGFloat topSpacing = (_collapseFlags & TGModernConversationItemCollapseTop) ? layoutConstants->topInsetCollapsed : layoutConstants->topInset;
    CGFloat bottomSpacing = (_collapseFlags & TGModernConversationItemCollapseBottom) ? layoutConstants->bottomInsetCollapsed : layoutConstants->bottomInset;
    
    if (isPost) {
        topSpacing = layoutConstants->topPostInset;
        bottomSpacing = layoutConstants->bottomPostInset;
    }
    
    CGSize headerSize = CGSizeZero;
    
    CGSize contentSize = _imageModel.frame.size;
    if (self.groupedLayout != nil)
        contentSize = [self.groupedLayout dimensions];
    
    bool updated = fabs(_imageModel.frame.size.width - contentSize.width) > FLT_EPSILON || fabs(_imageModel.frame.size.height - contentSize.height) > FLT_EPSILON;
    bool hasHeader = [self hasHeader];
    bool hasCaption = _caption.length > 0 && _positionFlags == TGMessageGroupPositionNone;
    
    if (hasHeader || hasCaption || _viaUserModel != nil || _webPageFooterModel != nil)
    {
        topSpacing += 3.0f - TGScreenPixel;
        bottomSpacing += 6.0f;
        
        if (_authorNameModel != nil)
        {
            CGFloat maxWidth = contentSize.width - 11.0f;
            CGFloat maxNameWidth = _viaUserModel == nil ? maxWidth : (maxWidth - 40.0f);
            
            if (_authorNameModel.frame.size.width < FLT_EPSILON || updated) {
                [_authorNameModel layoutForContainerSize:CGSizeMake(maxNameWidth, 0.0f)];
            }
            
            CGRect authorNameFrame = _authorNameModel.frame;
            authorNameFrame.origin = CGPointMake(3.0f, 1.0f + TGScreenPixel);
            _authorNameModel.frame = authorNameFrame;
            
            headerSize = CGSizeMake(_authorNameModel.frame.size.width, _authorNameModel.frame.size.height + 1.0f);
            
            if (_viaUserModel != nil) {
                [_viaUserModel layoutForContainerSize:CGSizeMake(maxWidth - _authorNameModel.frame.size.width, 0.0f)];
                CGRect viaUserFrame = _viaUserModel.frame;
                viaUserFrame.origin = CGPointMake(CGRectGetMaxX(_authorNameModel.frame) + 4.0f, 1.0f + TGScreenPixel);
                _viaUserModel.frame = viaUserFrame;
                
                headerSize.width += viaUserFrame.size.width + 4.0f;
            }
            
            if ((_replyHeaderModel == nil && _forwardedHeaderModel == nil)) {
                if (_caption.length > 0 || _webPageFooterModel != nil) {
                    headerSize.height += 7.0f;
                } else {
                    headerSize.height += 4.0f;
                }
            }
            
            if (_adminModel != nil) {
                [_adminModel layoutForContainerSize:CGSizeMake(maxWidth - _authorNameModel.frame.size.width - _viaUserModel.frame.size.width, CGFLOAT_MAX)];
                [_adminContentModel setNeedsSubmodelContentsUpdate];
            }
        } else if (_viaUserModel != nil) {
            [_viaUserModel layoutForContainerSize:CGSizeMake(320.0f - 80.0f - (_hasAvatar ? 38.0f : 0.0f), 0.0f)];
            
            CGRect viaUserFrame = _viaUserModel.frame;
            viaUserFrame.origin = CGPointMake(1.0f, 1.0f + TGScreenPixel);
            _viaUserModel.frame = viaUserFrame;
            
            headerSize = CGSizeMake(_viaUserModel.frame.size.width, _viaUserModel.frame.size.height + 1.0f);
            
            if ((_replyHeaderModel == nil && _forwardedHeaderModel == nil)) {
                if (_caption.length > 0 || _webPageFooterModel != nil) {
                    headerSize.height += 7.0f;
                } else {
                    headerSize.height += 4.0f;
                }
            }
        }
        
        if (_forwardedHeaderModel != nil)
        {
            if (_forwardedHeaderModel.frame.size.width < FLT_EPSILON || updated)
                [_forwardedHeaderModel layoutForContainerSize:CGSizeMake(contentSize.width - 11.0f, 0.0f)];
            
            CGRect forwardedHeaderFrame = _forwardedHeaderModel.frame;
            forwardedHeaderFrame.origin = CGPointMake(4.0f - TGScreenPixel, (_authorNameModel != nil ? 2.0f : 2.0f) + headerSize.height);
            _forwardedHeaderModel.frame = forwardedHeaderFrame;
            
            headerSize.height += forwardedHeaderFrame.size.height + 6;
            headerSize.width = MAX(headerSize.width, forwardedHeaderFrame.size.width + 4.0f);
        }
        
        if (_replyHeaderModel != nil)
        {
            if (_replyHeaderModel.frame.size.width < FLT_EPSILON || updated)
                [_replyHeaderModel layoutForContainerSize:CGSizeMake(contentSize.width - 11.0f, 0.0f)];
            
            CGRect replyHeaderFrame = _replyHeaderModel.frame;
            replyHeaderFrame.origin = CGPointMake(4.0f - TGScreenPixel, headerSize.height + 1.0f);
            _replyHeaderModel.frame = replyHeaderFrame;
            
            headerSize.height += replyHeaderFrame.size.height + 6;
            headerSize.width = MAX(headerSize.width, replyHeaderFrame.size.width + 4.0f);
        }
    }
    
    CGFloat avatarOffset = 0.0f;
    if (_hasAvatar)
        avatarOffset = 38.0f;
    
    CGFloat unsentOffset = 0.0f;
    if (!_incoming && _deliveryState == TGMessageDeliveryStateFailed)
        unsentOffset = 29.0f;
    
    CGRect imageFrame = _imageModel.frame;
    CGFloat leftOffset = _incomingAppearance ? (avatarOffset + layoutConstants->leftImageInset) : (containerSize.width - contentSize.width - layoutConstants->rightImageInset - unsentOffset);
    CGPoint layoutOrigin = CGPointMake(leftOffset, topSpacing + (isPost ? 2.0f : 0.0f));
    if (self.groupedLayout != nil)
    {
        if (!_editing && fabs(_replyPanOffset) > FLT_EPSILON)
            layoutOrigin.x += _replyPanOffset;
        
        CGRect inGroupFrame = [self.groupedLayout frameForMessageId:_message.mid];
        imageFrame = CGRectMake(layoutOrigin.x + inGroupFrame.origin.x, layoutOrigin.y + inGroupFrame.origin.y, inGroupFrame.size.width, inGroupFrame.size.height);
        
        if (_imagePosition != _positionFlags || fabs(_imageSize.width - imageFrame.size.width) > FLT_EPSILON || fabs(_imageSize.height - imageFrame.size.height) > FLT_EPSILON)
        {
            _imageSize = imageFrame.size;
            _imagePosition = _positionFlags;
            [self updateImage];
        }
        
        if (_incomingAppearance && _editing)
            imageFrame.origin.x += 42.0f;
        
        if (hasHeader)
        {
            if (_incomingAppearance)
                imageFrame.origin.x += 2.0f;
            else
                imageFrame.origin.x -= 2.0f;
            
            imageFrame.origin.y += headerSize.height;
        }
    }
    else
    {
        imageFrame = CGRectMake(_incomingAppearance ? (avatarOffset + layoutConstants->leftImageInset) : (containerSize.width - _originalImageSize.width - layoutConstants->rightImageInset - unsentOffset), topSpacing + (isPost ? 2.0f : 0.0f), _originalImageSize.width, _originalImageSize.height);
        if (_incomingAppearance && _editing)
        {
            imageFrame.origin.x += 42.0f;
            
            if (_temporaryHighlightView != nil)
            {
                CGFloat inset = _backgroundModel == nil ? 1.0f : 0.0f;
                _temporaryHighlightView.frame = CGRectInset(imageFrame, inset, inset);
            }
        }
        
        if (!_editing && fabs(_replyPanOffset) > FLT_EPSILON)
            imageFrame.origin.x += _replyPanOffset;
        
        if (_replyHeaderModel != nil || _forwardedHeaderModel || _caption.length > 0 || _viaUserModel != nil || _webPageFooterModel != nil)
        {
            if (_incomingAppearance)
                imageFrame.origin.x += 2.0f;
            else
                imageFrame.origin.x -= 2.0f;
            
            imageFrame.origin.y += headerSize.height;
        }
        
        if (_imagePosition != TGMessageGroupPositionNone || _imageSize.width > FLT_EPSILON)
        {
            _imageSize = CGSizeZero;
            _imagePosition = TGMessageGroupPositionNone;
            [self updateImage];
        }
        
        layoutOrigin = imageFrame.origin;
        contentSize = imageFrame.size;
    }
    
    _imageModel.frame = imageFrame;
    
    CGSize contentContainerSize = CGSizeMake(contentSize.width, 0.0f);
    
    bool hasSignature = false;
    if (_authorSignature.length != 0) {
        hasSignature = true;
        [_authorSignatureModel layoutForContainerSize:CGSizeMake(contentContainerSize.width - _messageViewsModel.frame.size.width - _editedLabelModel.frame.size.width - _dateModel.frame.size.width - 20.0f, CGFLOAT_MAX)];
    } else {
        _authorSignatureModel.frame = CGRectZero;
    }
    
    CGSize textSize = CGSizeZero;
    CGFloat infoWidth = 0.0f;
    if (!_incoming) {
        if (_messageViews == nil) {
            infoWidth += 12.0f;
        } else {
            infoWidth += MAX(0.0f, 12.0f - _messageViewsModel.frame.size.width);
            if (!isPost) {
                infoWidth += 12.0f;
            }
        }
    }
    infoWidth += _dateModel.frame.size.width + 10.0f;
    if (_editedLabelModel != nil) {
        infoWidth += _editedLabelModel.frame.size.width + 4.0f;
    }
    
    if (hasSignature) {
        infoWidth += _authorSignatureModel.frame.size.width + 6.0f;
    }
    
    if (_messageViews != nil) {
        infoWidth += _messageViewsModel.frame.size.width + 6.0f;
    }
    bool updateContent = false;
    if (hasCaption)
    {
        textSize = [self contentSizeForContainerSize:CGSizeMake(imageFrame.size.width - 12, containerSize.height) needsContentsUpdate:&updateContent infoWidth:infoWidth];
        textSize.height += 5.0;
        
        CGRect textFrame = _textModel.frame;
        textFrame.origin = CGPointMake(3.0f, imageFrame.origin.y + imageFrame.size.height - 3.0f + TGScreenPixel);
        
        if (_caption.length == 0 && _webPageFooterModel != nil) {
            textFrame.origin.y -= 19.0f;
        }
        
        if (isPost)
            textFrame.origin.y -= 2.0;
        
        _textModel.frame = textFrame;
    }
    
    if (_webPageFooterModel != nil && _positionFlags == TGMessageGroupPositionNone) {
        bool bottomInset = false;
        [_webPageFooterModel layoutForContainerSize:contentContainerSize contentSize:contentContainerSize infoWidth:infoWidth needsContentUpdate:&updateContent bottomInset:&bottomInset];
        _webPageFooterModel.frame = CGRectMake(_textModel.frame.origin.x, CGRectGetMaxY(_textModel.frame), _webPageFooterModel.frame.size.width, _webPageFooterModel.frame.size.height);
    }
    
    CGRect backgroundFrame = CGRectMake(imageFrame.origin.x - (_incomingAppearance ? 7.0f : 2.0f), topSpacing - 2.0f + (isPost ? 2.0f : 0.0f), contentSize.width + 9.0f, contentSize.height + 2.0f + topSpacing + headerSize.height + textSize.height);
    _backgroundModel.frame = backgroundFrame;
    
    if (_textModel == nil && (hasHeader || _viaUserModel != nil))
    {
        CGRect imageFrame = _imageModel.frame;
        if (self.groupedLayout != nil)
        {
            CGRect inGroupFrame = [self.groupedLayout frameForMessageId:_message.mid];
            imageFrame.origin.y = CGRectGetMaxY(backgroundFrame) - self.groupedLayout.dimensions.height + inGroupFrame.origin.y - 2;
        }
        else
        {
            imageFrame.origin.y = CGRectGetMaxY(backgroundFrame) - _imageModel.frame.size.height - 2;
        }
        _imageModel.frame = imageFrame;
    }
    
    _imageOrigin = CGPointMake(_imageModel.frame.origin.x, _imageModel.frame.origin.y);
    if (_editing && _incomingAppearance)
        _imageOrigin.x -= 42.0f;
    
    if (_backgroundModel == nil) {
        if (_actionButtonModel != nil) {
            _actionButtonModel.frame = CGRectOffset(_actionButtonModel.bounds, layoutOrigin.x + contentSize.width + 7.0f, layoutOrigin.y + contentSize.height - 29.0f - 1.0f);
        }
    } else {
        if (_actionButtonModel != nil) {
            _actionButtonModel.frame = CGRectOffset(_actionButtonModel.bounds, CGRectGetMaxX(backgroundFrame) + 7.0f, CGRectGetMaxY(backgroundFrame) - 29.0f - 1.0f);
        }
    }
    
    CGRect contentModelFrame = CGRectMake(imageFrame.origin.x + 3.0f + TGScreenPixel, backgroundFrame.origin.y + 2.0f, 0, 0);
    if (self.groupedLayout == nil)
    {
        contentModelFrame.size = CGSizeMake(contentSize.width + 1.0f, imageFrame.origin.y + contentSize.height + 1.0f + TGScreenPixel + textSize.height);
    }
    else
    {
        contentModelFrame.size = headerSize;
        if ((_contentModel.frame.size.width - contentModelFrame.size.width) > FLT_EPSILON)
            [_contentModel setNeedsSubmodelContentsUpdate];
    }
    
    if (_skipContentModelAnimation)
    {
        _skipContentModelAnimation = false;
        [UIView performWithoutAnimation:^
        {
            _contentModel.frame = contentModelFrame;
        }];
    }
    else
    {
         _contentModel.frame = contentModelFrame;
    }
    _adminContentModel.frame = CGRectMake(_backgroundModel.frame.origin.x + _backgroundModel.frame.size.width - _adminModel.frame.size.width - 1.0f - 11.0f, _contentModel.frame.origin.y + 3.0f + TGScreenPixel, _adminModel.frame.size.width, _adminModel.frame.size.height);
    _adminModel.frame = CGRectMake(0.0f, 0.0f, _adminModel.frame.size.width, _adminModel.frame.size.height);
    
    CGFloat limit = _viaUserModel != nil ? _contentModel.frame.origin.x + CGRectGetMaxX(_viaUserModel.frame) + 10.0f : _contentModel.frame.origin.x + CGRectGetMaxX(_authorNameModel.frame) + 10.0f;
    if (_adminModel.frame.origin.x < limit)
        _adminModel.hidden = true;
    
    _instantPreviewTouchAreaModel.frame = imageFrame;
    
    if (hasCaption || _webPageFooterModel != nil)
    {
        CGFloat dateOffset = -3.0f;
        _dateModel.frame = CGRectMake(_contentModel.frame.size.width - (_incomingAppearance ? 7 : 20.0f) - _dateModel.frame.size.width - 7.0f - TGScreenPixel, _contentModel.frame.size.height - 21.0f - (TGIsLocaleArabic() ? 1.0f : 0.0f) + dateOffset, _dateModel.frame.size.width, _dateModel.frame.size.height);
        
        _editedLabelModel.frame = CGRectMake(_dateModel.frame.origin.x - _editedLabelModel.frame.size.width - 4.0f, _dateModel.frame.origin.y, _editedLabelModel.frame.size.width, _editedLabelModel.frame.size.height);
        
        CGFloat signatureSize = (hasSignature ? (_authorSignatureModel.frame.size.width + 8.0f) : 0.0f);
        
        if (_progressModel != nil) {
            if (_incomingAppearance) {
                _progressModel.frame = CGRectMake(CGRectGetMaxX(_backgroundModel.frame) - _dateModel.frame.size.width - 29 - unsentOffset - TGScreenPixel - signatureSize, _contentModel.frame.origin.y + _contentModel.frame.size.height - 20 + 1.0f - TGScreenPixel + dateOffset, 15, 15);
            } else {
                _progressModel.frame = CGRectMake(containerSize.width - 28 - layoutConstants->rightInset - unsentOffset - TGScreenPixel - signatureSize, _contentModel.frame.origin.y + _contentModel.frame.size.height - 20 + 1.0f + dateOffset, 15, 15);
            }
        }
        
        if (_authorSignature.length != 0) {
            CGFloat minX = _dateModel.frame.origin.x;
            if (_editedLabelModel != nil) {
                minX = _editedLabelModel.frame.origin.x;
            }
            _authorSignatureModel.frame = CGRectMake(minX - _authorSignatureModel.frame.size.width - 6.0f, _dateModel.frame.origin.y - 1.0f, _authorSignatureModel.frame.size.width, _authorSignatureModel.frame.size.height);
        } else {
            _authorSignatureModel.frame = CGRectZero;
        }
        
        if (_messageViewsModel != nil) {
            CGFloat minX = _dateModel.frame.origin.x;
            if (_editedLabelModel != nil) {
                minX = _editedLabelModel.frame.origin.x;
            }
            if (_authorSignature.length != 0) {
                minX = _authorSignatureModel.frame.origin.x;
            }
            _messageViewsModel.frame = CGRectMake(minX - _messageViewsModel.frame.size.width - 6.0f + _contentModel.frame.origin.x, _dateModel.frame.origin.y + _contentModel.frame.origin.y + 2.0f + TGScreenPixel, _messageViewsModel.frame.size.width, _messageViewsModel.frame.size.height);
        }
        
        CGPoint stateOffset = _contentModel.frame.origin;
        if (_checkFirstModel != nil)
            _checkFirstModel.frame = CGRectMake((_checkFirstEmbeddedInContent ? 0.0f : stateOffset.x) + _contentModel.frame.size.width - 17 - 7.0f - TGScreenPixel, (_checkFirstEmbeddedInContent ? 0.0f : stateOffset.y) + _contentModel.frame.size.height - 17 + TGScreenPixel + dateOffset, 12, 11);
        
        if (_checkSecondModel != nil)
            _checkSecondModel.frame = CGRectMake((_checkSecondEmbeddedInContent ? 0.0f : stateOffset.x) + _contentModel.frame.size.width - 13 - 7.0f - TGScreenPixel, (_checkSecondEmbeddedInContent ? 0.0f : stateOffset.y) + _contentModel.frame.size.height - 17 + TGScreenPixel + dateOffset, 12, 11);
    }
    
    if (_unsentButtonModel != nil)
    {
        _unsentButtonModel.frame = CGRectMake(containerSize.width - _unsentButtonModel.frame.size.width - 9, contentSize.height + topSpacing + bottomSpacing + headerSize.height + textSize.height - _unsentButtonModel.frame.size.height - ((_collapseFlags & TGModernConversationItemCollapseBottom) ? 5 : 6), _unsentButtonModel.frame.size.width, _unsentButtonModel.frame.size.height);
    }
    
    CGFloat replyButtonsHeight = 0.0f;
    if (_replyButtonsModel != nil) {
        CGRect backgroundFrame = _imageModel.frame;
        CGFloat backgroundExtension = 10.0f;
        if (_backgroundModel != nil) {
            backgroundFrame = _backgroundModel.frame;
            backgroundExtension = 5.0f;
        }
        
        [_replyButtonsModel layoutForContainerSize:CGSizeMake(MIN(MAX([_replyButtonsModel minimumWidth], backgroundFrame.size.width + backgroundExtension), containerSize.width - 38.0f), containerSize.height)];
        
        _replyButtonsModel.frame = CGRectMake((_incomingAppearance ? backgroundFrame.origin.x : (CGRectGetMaxX(backgroundFrame) - _replyButtonsModel.frame.size.width)) + (_backgroundModel == nil ? (_incomingAppearance ? -5.0f : 5.0f) : 0.0f), CGRectGetMaxY(backgroundFrame), _replyButtonsModel.frame.size.width, _replyButtonsModel.frame.size.height);
        replyButtonsHeight = _replyButtonsModel.frame.size.height;
        self.avatarOffset = replyButtonsHeight;
    }
    else
    {
        self.avatarOffset = 7.0f;
    }
    
    CGRect frame = self.frame;
    frame.size = CGSizeMake(containerSize.width, contentSize.height + topSpacing + bottomSpacing + headerSize.height + textSize.height + 1.0f + replyButtonsHeight);
    self.frame = frame;
    
    [_contentModel updateSubmodelContentsIfNeeded];
    [_adminContentModel updateSubmodelContentsIfNeeded];
    
    [super layoutForContainerSize:containerSize];
}

- (CGRect)editingCheckButtonFrame
{
    if (_positionFlags == TGMessageGroupPositionNone)
        return [super editingCheckButtonFrame];
    
    return CGRectMake(_imageOrigin.x + _imageModel.frame.size.width - 30.0f - 5.0f + (_incomingAppearance ? 42.0f : 0.0f), _imageOrigin.y + 5.0f, 30.0f, 30.0f);
}

- (CGRect)editingCheckAreaFrame
{
    if (_positionFlags == TGMessageGroupPositionNone)
        return [super editingCheckButtonFrame];
    
    return CGRectOffset(_imageModel.frame, _incomingAppearance ? 42.0f : 0.0f, 0.0f);
}

- (int)defaultOverlayActionType
{
    return _isSecret ? (_isMessageViewed ? TGMessageImageViewOverlaySecretViewed : TGMessageImageViewOverlaySecret) : TGMessageImageViewOverlayNone;
}

- (void)refreshMetrics
{
    if (_textModel != nil)
        [_textModel setFont:textFontForSize(TGGetMessageViewModelLayoutConstants()->textFontSize - 1)];
}

- (void)clearLinkSelection
{
    for (UIView *linkView in _currentLinkSelectionViews)
    {
        [linkView removeFromSuperview];
    }
    _currentLinkSelectionViews = nil;
}

- (void)updateLinkSelection:(CGPoint)point
{
    if ([_contentModel boundView] != nil)
    {
        [self clearLinkSelection];
        
        CGPoint offset = CGPointMake(_contentModel.frame.origin.x - _backgroundModel.frame.origin.x, _contentModel.frame.origin.y - _backgroundModel.frame.origin.y);
        
        NSArray *regionData = nil;
        NSString *link = [_textModel linkAtPoint:CGPointMake(point.x - _textModel.frame.origin.x - offset.x, point.y - _textModel.frame.origin.y - offset.y) regionData:&regionData];
        
        CGPoint regionOffset = CGPointZero;
        
        if (link != nil)
        {
            CGRect topRegion = regionData.count > 0 ? [regionData[0] CGRectValue] : CGRectZero;
            CGRect middleRegion = regionData.count > 1 ? [regionData[1] CGRectValue] : CGRectZero;
            CGRect bottomRegion = regionData.count > 2 ? [regionData[2] CGRectValue] : CGRectZero;
            
            topRegion.origin = CGPointMake(topRegion.origin.x + regionOffset.x, topRegion.origin.y + regionOffset.y);
            middleRegion.origin = CGPointMake(middleRegion.origin.x + regionOffset.x, middleRegion.origin.y + regionOffset.y);
            bottomRegion.origin = CGPointMake(bottomRegion.origin.x + regionOffset.x, bottomRegion.origin.y + regionOffset.y);
            
            UIImageView *topView = nil;
            UIImageView *middleView = nil;
            UIImageView *bottomView = nil;
            
            UIImageView *topCornerLeft = nil;
            UIImageView *topCornerRight = nil;
            UIImageView *bottomCornerLeft = nil;
            UIImageView *bottomCornerRight = nil;
            
            NSMutableArray *linkHighlightedViews = [[NSMutableArray alloc] init];
            
            topView = [[UIImageView alloc] init];
            middleView = [[UIImageView alloc] init];
            bottomView = [[UIImageView alloc] init];
            
            topCornerLeft = [[UIImageView alloc] init];
            topCornerRight = [[UIImageView alloc] init];
            bottomCornerLeft = [[UIImageView alloc] init];
            bottomCornerRight = [[UIImageView alloc] init];
            
            if (topRegion.size.height != 0)
            {
                topView.hidden = false;
                topView.frame = topRegion;
                if (middleRegion.size.height == 0 && bottomRegion.size.height == 0)
                    topView.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkFull];
                else
                    topView.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkFull];
            }
            else
            {
                topView.hidden = true;
                topView.frame = CGRectZero;
            }
            
            if (middleRegion.size.height != 0)
            {
                middleView.hidden = false;
                middleView.frame = middleRegion;
                if (bottomRegion.size.height == 0)
                    middleView.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkFull];
                else
                    middleView.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkFull];
            }
            else
            {
                middleView.hidden = true;
                middleView.frame = CGRectZero;
            }
            
            if (bottomRegion.size.height != 0)
            {
                bottomView.hidden = false;
                bottomView.frame = bottomRegion;
                bottomView.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkFull];
            }
            else
            {
                bottomView.hidden = true;
                bottomView.frame = CGRectZero;
            }
            
            topCornerLeft.hidden = true;
            topCornerRight.hidden = true;
            bottomCornerLeft.hidden = true;
            bottomCornerRight.hidden = true;
            
            if (topRegion.size.height != 0 && middleRegion.size.height != 0)
            {
                if (topRegion.origin.x == middleRegion.origin.x)
                {
                    topCornerLeft.hidden = false;
                    topCornerLeft.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkCornerLR];
                    topCornerLeft.frame = CGRectMake(topRegion.origin.x, topRegion.origin.y + topRegion.size.height - 3.5f, 4, 7);
                }
                else if (topRegion.origin.x < middleRegion.origin.x + middleRegion.size.width - 3.5f)
                {
                    topCornerLeft.hidden = false;
                    topCornerLeft.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkCornerBT];
                    topCornerLeft.frame = CGRectMake(topRegion.origin.x - 3.5f, topRegion.origin.y + topRegion.size.height - 4, 7, 4);
                }
                
                if (topRegion.origin.x + topRegion.size.width == middleRegion.origin.x + middleRegion.size.width)
                {
                    topCornerRight.hidden = false;
                    topCornerRight.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkCornerRL];
                    topCornerRight.frame = CGRectMake(topRegion.origin.x + topRegion.size.width - 4, topRegion.origin.y + topRegion.size.height - 3.5f, 4, 7);
                }
                else if (topRegion.origin.x + topRegion.size.width < middleRegion.origin.x + middleRegion.size.width - 3.5f)
                {
                    topCornerRight.hidden = false;
                    topCornerRight.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkCornerBT];
                    topCornerRight.frame = CGRectMake(topRegion.origin.x + topRegion.size.width - 3.5f, topRegion.origin.y + topRegion.size.height - 4, 7, 4);
                }
                else if (bottomRegion.size.height == 0 && topRegion.origin.x < middleRegion.origin.x + middleRegion.size.width - 3.5f && topRegion.origin.x + topRegion.size.width > middleRegion.origin.x + middleRegion.size.width + 3.5f)
                {
                    topCornerRight.hidden = false;
                    topCornerRight.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkCornerTB];
                    topCornerRight.frame = CGRectMake(middleRegion.origin.x + middleRegion.size.width - 3.5f, middleRegion.origin.y, 7, 4);
                }
            }
            
            if (middleRegion.size.height != 0 && bottomRegion.size.height != 0)
            {
                if (middleRegion.origin.x == bottomRegion.origin.x)
                {
                    bottomCornerLeft.hidden = false;
                    bottomCornerLeft.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkCornerLR];
                    bottomCornerLeft.frame = CGRectMake(middleRegion.origin.x, middleRegion.origin.y + middleRegion.size.height - 3.5f, 4, 7);
                }
                
                if (bottomRegion.origin.x + bottomRegion.size.width < middleRegion.origin.x + middleRegion.size.width - 3.5f)
                {
                    bottomCornerRight.hidden = false;
                    bottomCornerRight.image = [[TGTelegraphConversationMessageAssetsSource instance] messageLinkCornerTB];
                    bottomCornerRight.frame = CGRectMake(bottomRegion.origin.x + bottomRegion.size.width - 3.5f, bottomRegion.origin.y, 7, 4);
                }
            }
            
            if (!topView.hidden)
                [linkHighlightedViews addObject:topView];
            if (!middleView.hidden)
                [linkHighlightedViews addObject:middleView];
            if (!bottomView.hidden)
                [linkHighlightedViews addObject:bottomView];
            
            if (!topCornerLeft.hidden)
                [linkHighlightedViews addObject:topCornerLeft];
            if (!topCornerRight.hidden)
                [linkHighlightedViews addObject:topCornerRight];
            if (!bottomCornerLeft.hidden)
                [linkHighlightedViews addObject:bottomCornerLeft];
            if (!bottomCornerRight.hidden)
                [linkHighlightedViews addObject:bottomCornerRight];
            
            for (UIView *partView in linkHighlightedViews)
            {
                partView.frame = CGRectOffset(partView.frame, _textModel.frame.origin.x, _textModel.frame.origin.y + 1);
                [[_contentModel boundView] addSubview:partView];
            }
            
            _currentLinkSelectionViews = linkHighlightedViews;
        }
    }
}

- (void)updateAssets {
    [super updateAssets];
    
    _actionButtonModel.image = [[TGTelegraphConversationMessageAssetsSource instance] systemShareButton];
}

- (void)actionPressed {
    if (_savedMessage)
    {
        int64_t peerId = 0;
        int32_t messageId = 0;
        for (TGMediaAttachment *attachment in _message.mediaAttachments)
        {
            if (attachment.type == TGForwardedMessageMediaAttachmentType)
            {
                peerId = ((TGForwardedMessageMediaAttachment *)attachment).forwardSourcePeerId ? : ((TGForwardedMessageMediaAttachment *)attachment).forwardPeerId;
                messageId = ((TGForwardedMessageMediaAttachment *)attachment).forwardMid ?: ((TGForwardedMessageMediaAttachment *)attachment).forwardPostId;
                break;
            }
        }
        
        [_context.companionHandle requestAction:@"peerAvatarTapped" options:@{@"peerId": @(peerId), @"messageId": @(messageId)}];
    }
    else
    {
        if (_positionFlags != TGMessageGroupPositionNone)
            [_context.companionHandle requestAction:@"fastForwardMessage" options:@{@"groupedId": @(_message.groupedId)}];
        else
            [_context.companionHandle requestAction:@"fastForwardMessage" options:@{@"mid": @(_mid)}];
    }
}

- (void)setupContentModel:(TGModernViewStorage *)viewStorage {
    if (_positionFlags == TGMessageGroupPositionUnknown)
        return;
    
    [self removeContentModel:viewStorage];
    
    if ((_positionFlags == TGMessageGroupPositionNone && (_replyHeader != nil || _caption.length != 0 || (_forwardPeer != nil && !_context.isSavedMessages) || _viaUser != nil || _webPageFooterModel != nil)) || (_positionFlags & TGMessageGroupPositionTop && _positionFlags & TGMessageGroupPositionLeft && [self hasHeader]))
    {
        static UIColor *incomingDateColor = nil;
        static UIColor *outgoingDateColor = nil;
        
        static TGTelegraphConversationMessageAssetsSource *assetsSource = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            assetsSource = [TGTelegraphConversationMessageAssetsSource instance];
            incomingDateColor = UIColorRGBA(0x525252, 0.6f);
            outgoingDateColor = UIColorRGBA(0x008c09, 0.8f);
        });
        
        _backgroundModel = [[TGTextMessageBackgroundViewModel alloc] initWithType:(_incomingAppearance) ? TGTextMessageBackgroundIncoming : TGTextMessageBackgroundOutgoing];
        [self insertSubmodel:_backgroundModel belowSubmodel:_imageModel];
        if (_isChannel) {
            [_backgroundModel setPartialMode:false];
        }
        
        _contentModel = [[TGModernFlatteningViewModel alloc] init];
        _contentModel.viewUserInteractionDisabled = true;
        [self insertSubmodel:_contentModel aboveSubmodel:_backgroundModel];
        
        if (_forwardPeer != nil && !_context.isSavedMessages)
        {
            static UIColor *incomingForwardColor = nil;
            static UIColor *outgoingForwardColor = nil;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                incomingForwardColor = UIColorRGBA(0x007bff, 1.0f);
                outgoingForwardColor = UIColorRGBA(0x00a516, 1.0f);
            });
            
            static NSRange formatNameRange;
            
            static int localizationVersion = -1;
            if (localizationVersion != TGLocalizedStaticVersion)
                formatNameRange = [TGLocalized(@"Message.ForwardedMessage") rangeOfString:@"%@"];
            
            NSString *authorName = @"";
            
            if ([_forwardPeer isKindOfClass:[TGUser class]]) {
                _forwardedPeerId = ((TGUser *)_forwardPeer).uid;
                authorName = ((TGUser *)_forwardPeer).displayName;
            } else if ([_forwardPeer isKindOfClass:[TGConversation class]]) {
                _forwardedPeerId = ((TGConversation *)_forwardPeer).conversationId;
                authorName = ((TGConversation *)_forwardPeer).chatTitle;
            }
            
            if ([_forwardAuthor isKindOfClass:[TGUser class]]) {
                authorName = [[NSString alloc] initWithFormat:@"%@ (%@)", authorName, ((TGUser *)_forwardAuthor).displayName];
            }
            
            NSString *text = [[NSString alloc] initWithFormat:TGLocalized(@"Message.ForwardedMessage"), authorName];
            
            NSMutableArray *additionalAttributes = [[NSMutableArray alloc] init];
            NSMutableArray *textCheckingResults = [[NSMutableArray alloc] init];
            
            NSArray *fontAttributes = [[NSArray alloc] initWithObjects:(__bridge id)[[TGTelegraphConversationMessageAssetsSource instance] messageForwardNameFont], (NSString *)kCTFontAttributeName, nil];
            
            if (_viaUser != nil) {
                NSString *formatString = [@" " stringByAppendingString:TGLocalized(@"Conversation.MessageViaUser")];
                NSString *viaUserName = [@"@" stringByAppendingString:_viaUser.userName == nil ? @"" : _viaUser.userName];
                NSRange range = [formatString rangeOfString:@"%@"];
                NSString *finalString = [[NSString alloc] initWithFormat:formatString, viaUserName];
                
                if (range.location != NSNotFound) {
                    range.location += text.length;
                    range.length = viaUserName.length;
                    [textCheckingResults addObject:[[TGTextCheckingResult alloc] initWithRange:range type:TGTextCheckingResultTypeLink contents:@"via"]];
                    [textCheckingResults addObject:[[TGTextCheckingResult alloc] initWithRange:range type:TGTextCheckingResultTypeUltraBold contents:nil]];
                }
                
                text = [text stringByAppendingString:finalString];
            }
            
            _forwardedHeaderModel = [[TGModernTextViewModel alloc] initWithText:text font:[[TGTelegraphConversationMessageAssetsSource instance] messageForwardTitleFont]];
            _forwardedHeaderModel.textColor = _incomingAppearance ? incomingForwardColor : outgoingForwardColor;
            _forwardedHeaderModel.layoutFlags = TGReusableLabelLayoutMultiline;
            _forwardedHeaderModel.textCheckingResults = textCheckingResults;
            if (formatNameRange.location != NSNotFound && authorName.length != 0)
            {
                NSRange range = NSMakeRange(formatNameRange.location, authorName.length);
                [additionalAttributes addObjectsFromArray:@[[[NSValue alloc] initWithBytes:&range objCType:@encode(NSRange)], fontAttributes]];
            }
            _forwardedHeaderModel.additionalAttributes = additionalAttributes;
            
            [_contentModel addSubmodel:_forwardedHeaderModel];
        }
        
        if (_authorPeer != nil)
        {
            NSString *title = @"";
            if ([_authorPeer isKindOfClass:[TGUser class]]) {
                if (_savedMessage && ((TGUser *)_authorPeer).uid == TGTelegraphInstance.clientUserId)
                    title = TGLocalized(@"DialogList.You");
                else
                    title = ((TGUser *)_authorPeer).displayName;
            } else if ([_authorPeer isKindOfClass:[TGConversation class]]) {
                title = ((TGConversation *)_authorPeer).chatTitle;
            }
            _authorNameModel = [[TGModernTextViewModel alloc] initWithText:title font:[[TGTelegraphConversationMessageAssetsSource instance] messageAuthorNameFont]];
            [_contentModel addSubmodel:_authorNameModel];
            _authorNameModel.textColor = _authorNameColor;
            
            static CTFontRef dateFont = NULL;
            static CTFontRef adminFont = NULL;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                if (iosMajorVersion() >= 7) {
                    dateFont = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGItalicSystemFontOfSize(12.0f) fontDescriptor], 0.0f, NULL);
                    adminFont = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGSystemFontOfSize(12.0f) fontDescriptor], 0.0f, NULL);
                } else {
                    UIFont *font = TGItalicSystemFontOfSize(12.0f);
                    dateFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
                    
                    font = TGSystemFontOfSize(12.0f);
                    adminFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
                }
            });
            _authorSignatureModel = [[TGModernTextViewModel alloc] initWithText:@"" font:dateFont];
            _authorSignatureModel.ellipsisString = @"\u2026,";
            _authorSignatureModel.textColor = _incomingAppearance ? incomingDateColor : outgoingDateColor;
            [_contentModel addSubmodel:_authorSignatureModel];
            
            if (_byAdmin)
            {
                _adminContentModel = [[TGModernFlatteningViewModel alloc] init];
                _adminContentModel.viewUserInteractionDisabled = true;
                [self insertSubmodel:_adminContentModel aboveSubmodel:_contentModel];
                [_adminContentModel bindViewToContainer:[_imageModel.boundView superview] viewStorage:viewStorage];
                
                _adminModel = [[TGModernTextViewModel alloc] initWithText:TGLocalized(@"Conversation.Admin") font:adminFont];
                _adminModel.textColor = UIColorRGB(0xb4b4b7);
                [_adminContentModel addSubmodel:_adminModel];
            }
        }
        
        if (_viaUser != nil && _forwardedHeaderModel == nil) {
            NSString *formatString = TGLocalized(@"Conversation.MessageViaUser");
            NSString *viaUserName = [@"@" stringByAppendingString:_viaUser.userName != nil ? _viaUser.userName : @""];
            //viaUserName = @"qwoifehiqowfhipoqewipfhqweiopfhpoiqwehfiohpqiew";
            NSRange range = [formatString rangeOfString:@"%@"];
            
            _viaUserModel = [[TGModernTextViewModel alloc] initWithText:[[NSString alloc] initWithFormat:formatString, viaUserName] font:[[TGTelegraphConversationMessageAssetsSource instance] messageAuthorNameFont]];
            if (range.location != NSNotFound) {
                _viaUserModel.textCheckingResults = @[[[TGTextCheckingResult alloc] initWithRange:NSMakeRange(range.location, viaUserName.length) type:TGTextCheckingResultTypeBold contents:nil]];
            }
            _viaUserModel.textColor = _incomingAppearance ? TGAccentColor() : UIColorRGB(0x00a700);
            [_contentModel addSubmodel:_viaUserModel];
        }
        
        if (_replyHeader != nil)
        {
            _replyMessageId = _replyHeader.mid;
            
            _replyHeaderModel = [TGContentBubbleViewModel replyHeaderModelFromMessage:_replyHeader peer:_replyAuthor incoming:_incomingAppearance system:false];
            [_contentModel addSubmodel:_replyHeaderModel];
        }
        
        bool hasCaption = _caption.length > 0 && _positionFlags == TGMessageGroupPositionNone;
        
        if (_caption.length != 0) {
            _authorSignatureModel.text = _authorSignature;
        }
        
        if (hasCaption || _webPageFooterModel != nil)
        {
            int daytimeVariant = 0;
            NSString *dateText = [TGDateUtils stringForShortTime:(int)_message.date daytimeVariant:&daytimeVariant];
            _dateModel = [[TGModernDateViewModel alloc] initWithText:dateText textColor:_incomingAppearance ? incomingDateColor : outgoingDateColor daytimeVariant:daytimeVariant];
            [_contentModel addSubmodel:_dateModel];
            
            if (!_incoming)
            {
                _checkFirstModel = [[TGModernImageViewModel alloc] initWithImage:_context.presentation.images.chatDeliveredIcon];
                _checkSecondModel = [[TGModernImageViewModel alloc] initWithImage:_context.presentation.images.chatReadIcon];
                
                if (_deliveryState == TGMessageDeliveryStatePending)
                {
                    _progressModel = [[TGModernClockProgressViewModel alloc] initWithType:_incomingAppearance ? TGModernClockProgressTypeIncomingClock : TGModernClockProgressTypeOutgoingClock];
                    [self addSubmodel:_progressModel];
                    
                    if (!_incomingAppearance) {
                        [self insertSubmodel:_checkFirstModel aboveSubmodel:_contentModel];
                        [self insertSubmodel:_checkSecondModel aboveSubmodel:_contentModel];
                    }
                    _checkFirstModel.alpha = 0.0f;
                    _checkSecondModel.alpha = 0.0f;
                }
                else if (_deliveryState == TGMessageDeliveryStateDelivered)
                {
                    if (!_incomingAppearance) {
                        [_contentModel addSubmodel:_checkFirstModel];
                    }
                    _checkFirstEmbeddedInContent = true;
                    
                    if (!_incomingAppearance) {
                        if (_read)
                        {
                            [_contentModel addSubmodel:_checkSecondModel];
                            _checkSecondEmbeddedInContent = true;
                        }
                        else
                        {
                            [self insertSubmodel:_checkSecondModel aboveSubmodel:_contentModel];
                            _checkSecondModel.alpha = 0.0f;
                        }
                    }
                }
            }
            
            _textModel = [[TGModernTextViewModel alloc] initWithText:_caption font:_captionFont != NULL ? _captionFont : textFontForSize(TGGetMessageViewModelLayoutConstants()->textFontSize - 1)];
            _textModel.textCheckingResults = _textCheckingResults;
            _textModel.textColor = [assetsSource messageTextColor];
            if (_message.isBroadcast)
                _textModel.additionalTrailingWidth += 10.0f;
            [_contentModel addSubmodel:_textModel];
            
            if (_messageViews != nil) {
                _messageViewsModel = [[TGMessageViewsViewModel alloc] init];
                _messageViewsModel.type = _incomingAppearance ? TGMessageViewsViewTypeIncoming : TGMessageViewsViewTypeOutgoing;
                _messageViewsModel.count = _messageViews.viewCount;
                [_messageViewsModel sizeToFit];
                [self addSubmodel:_messageViewsModel];
                _messageViewsModel.hidden = _deliveryState != TGMessageDeliveryStateDelivered;
            }
            
            if (!_ignoreEditing && _isEdited) {
                static CTFontRef dateFont = NULL;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^
                {
                    if (iosMajorVersion() >= 7) {
                        dateFont = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGItalicSystemFontOfSize(11.0f) fontDescriptor], 0.0f, NULL);
                    } else {
                        UIFont *font = TGItalicSystemFontOfSize(11.0f);
                        dateFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
                    }
                });
                _editedLabelModel = [[TGModernLabelViewModel alloc] initWithText:TGLocalized(@"Conversation.MessageEditedLabel") textColor:_dateModel.textColor font:dateFont maxWidth:CGFLOAT_MAX];
                [_contentModel addSubmodel:_editedLabelModel];
            }
        }
        
        if (_webPageFooterModel != nil) {
            [_contentModel addSubmodel:_webPageFooterModel];
        }
        
        if (!hasCaption && _webPageFooterModel == nil && (_positionFlags == TGMessageGroupPositionNone || (_positionFlags & TGMessageGroupPositionBottom && _positionFlags & TGMessageGroupPositionRight)))
        {
            [_imageModel setTimestampString:[self timestampString] signatureString:_authorSignature displayCheckmarks:!_incoming && !(_incomingAppearance && _context.isSavedMessages) && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:false];
            [_imageModel setDisplayTimestampProgress:_deliveryState == TGMessageDeliveryStatePending];
            _imageModel.timestampHidden = false;
        }
        else
        {
            _imageModel.timestampHidden = true;
        }
    } else {
        [self removeContentModel:viewStorage];
    }
}

- (void)removeContentModel:(TGModernViewStorage *)viewStorage {
    [self removeSubmodel:_backgroundModel viewStorage:viewStorage];
    _backgroundModel = nil;
    
    [self removeSubmodel:_contentModel viewStorage:viewStorage];
    
    _forwardedHeaderModel = nil;
    _authorNameModel = nil;
    _textModel = nil;
    _dateModel = nil;
    _authorSignatureModel = nil;
    
    [self removeSubmodel:_messageViewsModel viewStorage:viewStorage];
    _messageViewsModel = nil;
    
    [_contentModel removeSubmodel:_editedLabelModel viewStorage:viewStorage];
    
    [self removeSubmodel:_checkFirstModel viewStorage:viewStorage];
    _checkFirstModel = nil;
    
    [self removeSubmodel:_checkSecondModel viewStorage:viewStorage];
    _checkSecondModel = nil;
    
    [self removeSubmodel:_progressModel viewStorage:viewStorage];
    _progressModel = nil;
    
    [self removeSubmodel:_adminContentModel viewStorage:viewStorage];
    _adminContentModel = nil;
    
    [self removeSubmodel:_adminModel viewStorage:viewStorage];
    _adminModel = nil;
    
    [_imageModel setTimestampString:[self timestampString] signatureString:_authorSignature displayCheckmarks:!_incoming && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:false];
    [_imageModel setDisplayTimestampProgress:_deliveryState == TGMessageDeliveryStatePending];
    
    if ((_positionFlags != TGMessageGroupPositionNone && !(_positionFlags & TGMessageGroupPositionBottom && _positionFlags & TGMessageGroupPositionRight)))
        _imageModel.timestampHidden = true;
    else
        _imageModel.timestampHidden = false;
    
    _contentModel = nil;
}

- (void)setWebPageFooter:(TGWebPageMediaAttachment *)webPage invoice:(TGInvoiceMediaAttachment *)invoice viewStorage:(TGModernViewStorage *)viewStorage
{
    _webPage = webPage;
    if (webPage.url.length == 0 && ![webPage.pageType isEqualToString:@"game"] && ![webPage.pageType isEqualToString:@"invoice"] && ![webPage.pageType isEqualToString:@"message"])
    {
    }
    else
    {
        bool isAnimationOrVideo = false;
        bool imageInText = true;
        if ([webPage.pageType isEqualToString:@"photo"] || [webPage.pageType isEqualToString:@"video"] || [webPage.pageType isEqualToString:@"gif"] || [webPage.pageType isEqualToString:@"game"] || [webPage.pageType isEqualToString:@"invoice"] || [webPage.pageType isEqualToString:@"message"]) {
            imageInText = false;
            isAnimationOrVideo = true;
        } else if ([webPage.pageType isEqualToString:@"article"]) {
            CGSize imageSize = CGSizeZero;
            [webPage.photo.imageInfo imageUrlForLargestSize:&imageSize];
            if (imageSize.width > 400.0f && webPage.instantPage != nil) {
                imageInText = false;
            }
        }
        
        if ([webPage.document.mimeType isEqualToString:@"image/gif"]) {
            imageInText = false;
        }
        
        bool isMusic = false;
        bool isVoice = false;
        bool isSticker = false;
        bool isRoundVideo = false;
        
        for (id attribute in webPage.document.attributes) {
            if ([attribute isKindOfClass:[TGDocumentAttributeAudio class]]) {
                if (((TGDocumentAttributeAudio *)attribute).isVoice) {
                    isVoice = true;
                } else {
                    isMusic = true;
                }
            } else if ([attribute isKindOfClass:[TGDocumentAttributeVideo class]]) {
                if (((TGDocumentAttributeVideo *)attribute).isRoundMessage) {
                    isRoundVideo = true;
                }
                else {
                    isAnimationOrVideo = true;
                }
            } else if ([attribute isKindOfClass:[TGDocumentAttributeSticker class]]) {
                isSticker = true;
            }
        }
        
        if (isVoice) {
            _webPageFooterModel = [[TGAudioWebpageFooterModel alloc] initWithContext:_context messageId:_mid incoming:_incomingAppearance webPage:webPage hasViews:_messageViews != nil];
            _webPageFooterModel.mediaIsAvailable = _mediaIsAvailable;
            //[_webPageFooterModel updateMediaProgressVisible:_mediaProgressVisible mediaProgress:_mediaProgress animated:false];
            _webPageFooterModel.boundToContainer = _boundToContainer;
            [_contentModel addSubmodel:_webPageFooterModel];
        } else if (isMusic) {
            _webPageFooterModel = [[TGMusicWebpageFooterModel alloc] initWithContext:_context messageId:_mid incoming:_incomingAppearance webPage:webPage hasViews:_messageViews != nil];
            _webPageFooterModel.mediaIsAvailable = _mediaIsAvailable;
            //[_webPageFooterModel updateMediaProgressVisible:_mediaProgressVisible mediaProgress:_mediaProgress animated:false];
            _webPageFooterModel.boundToContainer = _boundToContainer;
            [_contentModel addSubmodel:_webPageFooterModel];
        } else if (isSticker) {
            _webPageFooterModel = [[TGStickerWebpageFooterModel alloc] initWithContext:_context incoming:_incomingAppearance webPage:webPage hasViews:_messageViews != nil];
            _webPageFooterModel.mediaIsAvailable = _mediaIsAvailable;
            //[_webPageFooterModel updateMediaProgressVisible:_mediaProgressVisible mediaProgress:_mediaProgress animated:false];
            _webPageFooterModel.boundToContainer = _boundToContainer;
            [_contentModel addSubmodel:_webPageFooterModel];
        } else if (isRoundVideo) {
            _webPageFooterModel = [[TGRoundVideoWebpageFooterModel alloc] initWithContext:_context messageId:_mid incoming:_incomingAppearance webPage:webPage];
            _webPageFooterModel.mediaIsAvailable = _mediaIsAvailable;
            //[_webPageFooterModel updateMediaProgressVisible:_mediaProgressVisible mediaProgress:_mediaProgress animated:false];
            _webPageFooterModel.boundToContainer = _boundToContainer;
            [_contentModel addSubmodel:_webPageFooterModel];
        } else if (webPage.photo == nil && webPage.document != nil && !isAnimationOrVideo) {
            _webPageFooterModel = [[TGDocumentWebpageFooterModel alloc] initWithContext:_context incoming:_incomingAppearance webPage:webPage hasViews:_messageViews != nil];
            _webPageFooterModel.mediaIsAvailable = _mediaIsAvailable;
            //[_webPageFooterModel updateMediaProgressVisible:_mediaProgressVisible mediaProgress:_mediaProgress animated:false];
            _webPageFooterModel.boundToContainer = _boundToContainer;
            [_contentModel addSubmodel:_webPageFooterModel];
        } else {
            _webPageFooterModel = [[TGArticleWebpageFooterModel alloc] initWithContext:_context incoming:_incomingAppearance webPage:webPage imageInText:imageInText invoice:invoice];
            _webPageFooterModel.mediaIsAvailable = _mediaIsAvailable;
            //[_webPageFooterModel updateMediaProgressVisible:_mediaProgressVisible mediaProgress:_mediaProgress animated:false];
            _webPageFooterModel.boundToContainer = _boundToContainer;
            __weak TGImageMessageViewModel *weakSelf = self;
            ((TGArticleWebpageFooterModel *)_webPageFooterModel).instantPagePressed = ^{
                __strong TGImageMessageViewModel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf instantPageButtonPressed];
                }
            };
            ((TGArticleWebpageFooterModel *)_webPageFooterModel).viewGroupPressed = ^{
                __strong TGImageMessageViewModel *strongSelf = weakSelf;
                if (strongSelf != nil && webPage.url != nil) {
                    [strongSelf->_context.companionHandle requestAction:@"openLinkRequested" options:@{@"url": webPage.url}];
                }
            };
            [_contentModel addSubmodel:_webPageFooterModel];
        }
    }
    
    if ([_contentModel boundView] != nil)
    {
        [_webPageFooterModel bindSpecialViewsToContainer:_contentModel.boundView viewStorage:viewStorage atItemPosition:CGPointMake(_boundOffset.x + _webPageFooterModel.frame.origin.x, _boundOffset.y + _webPageFooterModel.frame.origin.y)];
    }
    
    [self setupContentModel:viewStorage];
}

- (void)instantPageButtonPressed {
    
}

- (bool)isInstant {
    return false;
}

- (void)avatarTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        int64_t peerId = _message.fromUid;
        bool peer = !TGPeerIdIsUser(peerId);
        if (_context.isSavedMessages)
        {
            for (TGMediaAttachment *attachment in _message.mediaAttachments)
            {
                if (attachment.type == TGForwardedMessageMediaAttachmentType)
                {
                    peerId = ((TGForwardedMessageMediaAttachment *)attachment).forwardPeerId;
                    peer = true;
                    break;
                }
            }
        }
        
        if (peer)
        {
            [_context.companionHandle requestAction:@"peerAvatarTapped" options:@{@"peerId": @(peerId), @"messageId": @(_mid), @"chat": @(_context.isSavedMessages)}];
        }
        else
        {
           [_context.companionHandle requestAction:@"userAvatarTapped" options:@{@"uid": @(peerId), @"mid": @(_mid)}];
        }
    }
}

- (bool (^)(CGPoint))pointInside
{
    if (_positionFlags == TGMessageGroupPositionNone)
        return nil;
    
    return ^bool (CGPoint point)
    {
        return CGRectContainsPoint(_imageModel.frame, point) || (_groupCheckButtonModel != nil && CGRectContainsPoint(_groupCheckButtonModel.frame, point)) || [self insideGroupCheckArea:point] || [self insideBackground:point] || (!_avatarModel.hidden && CGRectContainsPoint(_avatarModel.frame, point)) || (!_actionButtonModel.hidden && CGRectContainsPoint(_actionButtonModel.frame, point)) || (!_unsentButtonModel.hidden && CGRectContainsPoint(_unsentButtonModel.frame, point)) || (_replyHeaderModel != nil && CGRectContainsPoint(CGRectOffset(_replyHeaderModel.frame, _contentModel.frame.origin.x, _contentModel.frame.origin.y), point)) || (_forwardedHeaderModel != nil && CGRectContainsPoint(CGRectOffset(_forwardedHeaderModel.frame, _contentModel.frame.origin.x, _contentModel.frame.origin.y), point)) || (_unsentButtonModel != nil && CGRectContainsPoint(_unsentButtonModel.frame, point));
    };
}

- (bool)insideGroupCheckArea:(CGPoint)point
{
    if (_groupCheckAreaModel == nil)
        return false;
    
    if (point.x < _imageModel.frame.origin.x)
        return true;
    
    if (point.x > _imageModel.frame.origin.x + self.groupedLayout.dimensions.width)
        return true;
    
    return false;
}

- (bool)insideBackground:(CGPoint)point
{
    if (_backgroundModel == nil)
        return false;
    
    if (!CGRectContainsPoint(_backgroundModel.frame, point))
        return false;
    
    CGRect frame = [_groupedLayout frameForMessageId:_message.mid];
    CGPoint offset = CGPointMake(_imageModel.frame.origin.x - frame.origin.x, _imageModel.frame.origin.y - frame.origin.y);
    
    __block bool hitOtherMessage = false;
    [_groupedLayout enumerateMessageFrames:^(int32_t messageId, CGRect frame)
    {
        if (messageId == _message.mid || hitOtherMessage)
            return;
        
        CGRect messageFrame = CGRectOffset(frame, offset.x, offset.y);
        if (CGRectContainsPoint(messageFrame, point))
            hitOtherMessage = true;
    }];
    
    return !hitOtherMessage;
}

- (void)updateEditingState:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage animationDelay:(NSTimeInterval)animationDelay
{
    if (!_needsEditingCheckButton)
        return;
    
    if (_positionFlags & TGMessageGroupPositionTop && _positionFlags & TGMessageGroupPositionLeft)
    {
        bool editing = _context.editing;
        
        if (editing != _editing)
        {
            if (editing)
            {
                if (_groupCheckAreaModel == nil)
                {
                    _groupCheckAreaModel = [[TGModernButtonViewModel alloc] init];
                    _groupCheckAreaModel.skipDrawInContext = true;
                    _groupCheckAreaModel.frame = [super editingCheckAreaFrame];
                    [self addSubmodel:_groupCheckAreaModel];
                    
                    if (container != nil)
                    {
                        [_groupCheckAreaModel bindViewToContainer:container viewStorage:viewStorage];
                        
                        [(UIButton *)[_groupCheckAreaModel boundView] addTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
            }
            else if (_groupCheckAreaModel != nil)
            {
                if ([_groupCheckAreaModel boundView] != nil)
                {
                    [(UIButton *)[_groupCheckAreaModel boundView] removeTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                }
                
                [self removeSubmodel:_groupCheckAreaModel viewStorage:viewStorage];
                _groupCheckAreaModel = nil;
            }
            
            if (animationDelay > -FLT_EPSILON && container != nil)
            {
                UIView<TGModernView> *checkView = nil;
                
                if (editing)
                {
                    if (_groupCheckButtonModel == nil)
                    {
                        _groupCheckButtonModel = [[TGModernCheckButtonViewModel alloc] initWithFrame:[super editingCheckButtonFrame]];
                        _groupCheckButtonModel.isChecked = [_context isGroupChecked:_message.groupedId];
                        [self addSubmodel:_groupCheckButtonModel];
                        
                        if (container != nil)
                        {
                            [_groupCheckButtonModel bindViewToContainer:container viewStorage:viewStorage];
                            
                            [(UIButton *)[_groupCheckButtonModel boundView] addTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                        }
                    }
                    
                    [_groupCheckButtonModel boundView].frame = CGRectOffset(_groupCheckButtonModel.frame, -49.0f, 0.0f);
                }
                else if (_groupCheckButtonModel != nil)
                {
                    if ([_groupCheckButtonModel boundView] != nil)
                    {
                        [(UIButton *)[_groupCheckButtonModel boundView] removeTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                    }
                    
                    [self removeSubmodel:_groupCheckButtonModel viewStorage:viewStorage];
                    checkView = [_groupCheckButtonModel _dequeueView:viewStorage];
                    checkView.frame = _groupCheckButtonModel.frame;
                    [container addSubview:checkView];
                    _groupCheckButtonModel = nil;
                }
                
                UIViewAnimationOptions options = UIViewAnimationOptionAllowAnimatedContent;
                if (iosMajorVersion() >= 7)
                    options |= 7 << 16;
                [UIView animateWithDuration:MAX(0.025, 0.18 - animationDelay) delay:animationDelay options:options animations:^
                {
                    if (self.frame.size.width > FLT_EPSILON)
                        [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
                    
                    if (editing)
                        [_groupCheckButtonModel boundView].frame = _groupCheckButtonModel.frame;
                    else
                        checkView.frame = CGRectOffset(checkView.frame, -49.0f, 0.0f);
                } completion:^(__unused BOOL finished)
                {
                    if (checkView != nil)
                    {
                        [checkView removeFromSuperview];
                        checkView.transform = CGAffineTransformIdentity;
                        [viewStorage enqueueView:checkView];
                    }
                }];
            }
            else
            {
                if (self.frame.size.width > FLT_EPSILON)
                    [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
                
                if (editing)
                {
                    if (_groupCheckButtonModel == nil)
                    {
                        _groupCheckButtonModel = [[TGModernCheckButtonViewModel alloc] initWithFrame:[super editingCheckButtonFrame]];
                        _groupCheckButtonModel.isChecked = [_context isGroupChecked:_message.groupedId];
                        [self addSubmodel:_groupCheckButtonModel];
                        
                        if (container != nil)
                        {
                            [_groupCheckButtonModel bindViewToContainer:container viewStorage:viewStorage];
                            
                            [(UIButton *)[_groupCheckButtonModel boundView] addTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                        }
                    }
                }
                else if (_groupCheckButtonModel != nil)
                {
                    if ([_groupCheckButtonModel boundView] != nil)
                    {
                        [(UIButton *)[_groupCheckButtonModel boundView] removeTarget:self action:@selector(groupCheckButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                    }
                    
                    [self removeSubmodel:_groupCheckButtonModel viewStorage:viewStorage];
                    _groupCheckButtonModel = nil;
                }
            }
        }
        else if (editing)
            _groupCheckButtonModel.isChecked = [_context isGroupChecked:_message.groupedId];
    }
    
    [super updateEditingState:container viewStorage:viewStorage animationDelay:animationDelay];
}

- (void)groupCheckButtonPressed
{
    if (_groupCheckButtonModel != nil)
    {
        _groupCheckButtonModel.isChecked = !_groupCheckButtonModel.isChecked;
        [_context.companionHandle requestAction:@"messageGroupSelectionChanged" options:@{@"groupedId": @(_message.groupedId), @"selected": @(_groupCheckButtonModel.isChecked)}];
    }
}

@end
