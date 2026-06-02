
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface ViewController : UIViewController
@property (nonatomic, strong) id<MTLDevice> metalDevice;
@property (nonatomic, strong) CAMetalLayer *metalLayer;
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

extern void ios_render_frame(void);
extern void ios_handle_touch(float x, float y, int action);

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.metalDevice = MTLCreateSystemDefaultDevice();
    
    if (!self.metalDevice) {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    [self setupMetalLayer];
    [self setupDisplayLink];
}

- (void)setupMetalLayer {
    self.metalLayer = [CAMetalLayer layer];
    self.metalLayer.device = self.metalDevice;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.metalLayer.framebufferOnly = YES;
    self.metalLayer.frame = self.view.bounds;
    self.metalLayer.contentsScale = self.view.contentScaleFactor;
    
    [self.view.layer addSublayer:self.metalLayer];
}

- (void)setupDisplayLink {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderFrame)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)renderFrame {
    if (ios_render_frame) {
        ios_render_frame();
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if (ios_handle_touch) {
        ios_handle_touch(point.x, point.y, 0);
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if (ios_handle_touch) {
        ios_handle_touch(point.x, point.y, 1);
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if (ios_handle_touch) {
        ios_handle_touch(point.x, point.y, 2);
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.metalLayer.frame = self.view.bounds;
}

- (CAMetalLayer *)getMetalLayer {
    return self.metalLayer;
}

@end
