//
//  CubeIndex.m
//  OpenGLES
//
//  Created by Chenfy on 2020/5/30.
//  Copyright © 2020 Chenfy. All rights reserved.
//

#import "CubeIndex.h"

@interface CubeIndex ()
{
    GLuint vbo;
    GLuint vao;
    
    GLuint indiceVbo;
}
@property (strong, nonatomic) GLKTextureInfo *normalMap;
@property (strong, nonatomic) GLKTextureInfo *diffuseMap;
@end

@implementation CubeIndex

- (id)initWithGLContext:(GLContext *)context diffuseMap:(GLKTextureInfo *)diffuseMap normalMap:(GLKTextureInfo *)normalMap {
    self = [super initWithGLContext:context];
    if (self) {
        self.modelMatrix = GLKMatrix4Identity;
        [self genVBO];
        [self genIndiceVBO];
        [self genVAO];

        self.diffuseMap = diffuseMap;
        self.normalMap = normalMap;
    }
    return self;
}

- (void)dealloc {
    glDeleteBuffers(1, &vbo);
    glDeleteBuffers(1, &vao);
}

- (void)genVBO {
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, 8 * 8 * sizeof(GLfloat), [self cubeVertex], GL_STATIC_DRAW);
}

- (void)genIndiceVBO {
    glGenBuffers(1, &indiceVbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indiceVbo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 36 * sizeof(GLushort), [self cubeVertexIndice], GL_STATIC_DRAW);
}

- (void)genVAO {
    glGenVertexArraysOES(1, &vao);
    glBindVertexArrayOES(vao);
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indiceVbo);

    [self.context bindAttribs:NULL];
    
    glBindVertexArrayOES(0);
}

- (void)update:(NSTimeInterval)timeSinceLastUpdate {
    float varyingFactor = (sin(timeSinceLastUpdate) + 1) / 2.0; // 0 ~ 1
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(varyingFactor * M_PI * 2, 1, 1, 1);
    self.modelMatrix = rotateMatrix;
}

- (void)draw:(GLContext *)glContext {
    [glContext setUniformMatrix4fv:@"modelMatrix" value:self.modelMatrix];
    bool canInvert;
    GLKMatrix4 normalMatrix = GLKMatrix4InvertAndTranspose(self.modelMatrix, &canInvert);
    [glContext setUniformMatrix4fv:@"normalMatrix" value:canInvert ? normalMatrix : GLKMatrix4Identity];
    [glContext bindTexture:self.diffuseMap to:GL_TEXTURE0 uniformName:@"diffuseMap"];
    [glContext bindTexture:self.normalMap to:GL_TEXTURE1 uniformName:@"normalMap"];

    [glContext drawTrianglesWithIndicedVAO:vao vertexCount:36];
}


#pragma mark -- 数据源
- (GLfloat *)cubeVertex {
    static GLfloat cubeData[] = {
        0.5,  -0.5,    0.5f, 0.5773502691896258, -0.5773502691896258, 0.5773502691896258, 0, 0,   // VertexA
        0.5,  -0.5f,  -0.5f, 0.5773502691896258, -0.5773502691896258, -0.5773502691896258, 0, 1,   // VertexB
        0.5,  0.5f,   -0.5f, 0.5773502691896258, 0.5773502691896258, -0.5773502691896258, 1, 1,   // VertexC
        0.5,  0.5f,    0.5f, 0.5773502691896258, 0.5773502691896258, 0.5773502691896258, 1, 0,   // VertexD
        -0.5,  -0.5,    0.5f, -0.5773502691896258, -0.5773502691896258, 0.5773502691896258, 0, 0, // VertexE
        -0.5,  -0.5f,  -0.5f, -0.5773502691896258, -0.5773502691896258, -0.5773502691896258, 0, 1, // VertexF
        -0.5,  0.5f,   -0.5f, -0.5773502691896258, 0.5773502691896258, -0.5773502691896258, 1, 1, // VertexG
        -0.5,  0.5f,    0.5f, -0.5773502691896258, 0.5773502691896258, 0.5773502691896258, 1, 0, // VertexH
    };
    return cubeData;
}

- (GLushort *)cubeVertexIndice {
    static GLushort cubeDataIndice[] = {
        0,      // VertexA
        1,      // VertexB
        2,      // VertexC
        2,      // VertexC
        3,      // VertexD
        0,      // VertexA
        
        4,      // VertexE
        5,      // VertexF
        6,      // VertexG
        6,      // VertexG
        7,      // VertexH
        4,      // VertexE
        
        7,      // VertexH
        6,      // VertexG
        2,      // VertexC
        2,      // VertexC
        3,      // VertexD
        7,      // VertexH
        4,      // VertexE
        5,      // VertexF
        1,      // VertexB
        1,      // VertexB
        0,      // VertexA
        4,      // VertexE
        
        7,      // VertexH
        4,      // VertexE
        0,      // VertexA
        0,      // VertexA
        3,      // VertexD
        7,      // VertexH
        6,      // VertexG
        5,      // VertexF
        1,      // VertexB
        1,      // VertexB
        2,      // VertexC
        6,      // VertexG
    };
    return cubeDataIndice;
}
@end
