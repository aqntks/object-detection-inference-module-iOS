#import "InferenceModule.h"
#import <LibTorch/LibTorch.h>

const int input_width = 640;
const int input_height = 640;
const int output_size = 25200*20;

@implementation InferenceModule {
    @protected torch::jit::script::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
    self = [super init];
    if (self) {
        try {
            _impl = torch::jit::load(filePath.UTF8String);
            _impl.eval();
        } catch (const std::exception& exception) {
            NSLog(@"%s", exception.what());
            return nil;
        }
    }
    return self;
}

- (NSArray<NSNumber*>*)detectImage:(void*)imageBuffer {
    try {
        at::Tensor tensor = torch::from_blob(imageBuffer, { 1, 3, input_width, input_height }, at::kFloat);
        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
        
        auto outputTuple = _impl.forward({ tensor }).toTuple();
        auto outputTensor = outputTuple->elements()[0].toTensor();

        float* floatBuffer = outputTensor.data_ptr<float>();
        if (!floatBuffer) {
            return nil;
        }
        
        NSMutableArray* results = [[NSMutableArray alloc] init];
        for (int i = 0; i < output_size; i++) {
          [results addObject:@(floatBuffer[i])];
        }
        return [results copy];
        
    } catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}

@end
