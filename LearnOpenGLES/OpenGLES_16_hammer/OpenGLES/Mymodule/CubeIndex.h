//
//  CubeIndex.h
//  OpenGLES
//
//  Created by Chenfy on 2020/5/30.
//  Copyright © 2020 Chenfy. All rights reserved.
//

#import "GLObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface CubeIndex : GLObject

- (id)initWithGLContext:(GLContext *)context diffuseMap:(GLKTextureInfo *)diffuseMap normalMap:(GLKTextureInfo *)normalMap;
- (void)update:(NSTimeInterval)timeSinceLastUpdate;
- (void)draw:(GLContext *)glContext;

@end

NS_ASSUME_NONNULL_END
