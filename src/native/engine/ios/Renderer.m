
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface Renderer : NSObject
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, assign) float redColor;
@property (nonatomic, assign) float greenColor;
@property (nonatomic, assign) float blueColor;
- (instancetype)initWithMetalLayer:(CAMetalLayer *)layer;
- (void)render;
- (void)setClearColorRed:(float)r green:(float)g blue:(float)b;
@end

@implementation Renderer
{
    CAMetalLayer *_metalLayer;
    id<MTLCommandBuffer> _commandBuffer;
    id<MTLRenderCommandEncoder> _renderEncoder;
    MTLRenderPassDescriptor *_renderPassDescriptor;
}

- (instancetype)initWithMetalLayer:(CAMetalLayer *)layer {
    self = [super init];
    if (self) {
        _metalLayer = layer;
        _device = layer.device;
        _commandQueue = [_device newCommandQueue];
        _redColor = 0.39f;
        _greenColor = 0.59f;
        _blueColor = 0.78f;
        
        [self buildPipeline];
    }
    return self;
}

- (void)buildPipeline {
    id<MTLLibrary> library = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    
    MTLRenderPipelineDescriptor *pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDesc.vertexFunction = vertexFunction;
    pipelineDesc.fragmentFunction = fragmentFunction;
    pipelineDesc.colorAttachments[0].pixelFormat = _metalLayer.pixelFormat;
    
    NSError *error = nil;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    
    if (error) {
        NSLog(@"Failed to create pipeline state: %@", error);
    }
}

- (void)render {
    id<CAMetalDrawable> drawable = [_metalLayer nextDrawable];
    if (!drawable) return;
    
    _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    _renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(_redColor, _greenColor, _blueColor, 1.0f);
    _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [renderEncoder setRenderPipelineState:_pipelineState];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [renderEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)setClearColorRed:(float)r green:(float)g blue:(float)b {
    _redColor = r;
    _greenColor = g;
    _blueColor = b;
}

@end
