//
//  ViewController.m
//  OpenGLES
//
//  Created by Chenfy on 2020/5/17.
//  Copyright © 2020 Chenfy. All rights reserved.
//

#import "ViewController.h"
#import "GLContext.h"
#import "Terrain.h"
#import "GLGeometry.h"

#define KLogFun NSLog(@"__func___:%s",__func__)

@interface ViewController ()<GLKViewDelegate>
@property (assign, nonatomic)GLfloat         elapsedTime;
@property (strong, nonatomic)EAGLContext     *context;
@property (nonatomic, strong)GLContext      *glContext;
@property (nonatomic, strong)NSMutableArray *objects;

@property(nonatomic,strong)NSMutableArray *terrainMeshStrips;

@property(nonatomic,strong)Terrain *terrain;
@property(nonatomic,strong)UIImage *heightMap;
@property(nonatomic,assign)CGSize   terrainSize;
@property(nonatomic,assign)GLfloat  terrainHeight;



@property (strong, nonatomic) GLKTextureInfo *difuseMap;
@property (strong, nonatomic) GLKTextureInfo *normalMap;

@property (assign, nonatomic) GLKMatrix4 projectionMatrix; // 投影矩阵
@property (assign, nonatomic) GLKMatrix4 cameraMatrix; // 观察矩阵
@property (assign, nonatomic) GLKMatrix4 modelMatrix; // 矩形的模型变换
@end

@implementation ViewController

- (NSMutableArray *)objects {
    if (!_objects) {
        _objects = [NSMutableArray arrayWithCapacity:3];
    }
    return _objects;
}
- (NSMutableArray *)terrainMeshStrips {
    if (!_terrainMeshStrips) {
        _terrainMeshStrips = [NSMutableArray arrayWithCapacity:3];
    }
    return _terrainMeshStrips;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 使用透视投影矩阵
    float aspect = self.view.frame.size.width / self.view.frame.size.height;
    self.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), aspect, 0.1, 100.0);
    // 设置摄像机在 0，0，2 坐标，看向 0，0，0点。Y轴正向为摄像机顶部指向的方向
    self.cameraMatrix = GLKMatrix4MakeLookAt(0, 0, 2, 0, 0, 0, 0, 1, 0);
    // 先初始化矩形的模型矩阵为单位矩阵
    self.modelMatrix = GLKMatrix4Identity;
    
    [self setupContext];
    
    // Do any additional setup after loading the view.
}

/** 设置 OpenGLES EAGLContext 上下文
 */
- (void)setupContext {
    // 使用OpenGL ES2, ES2之后都采用Shader来管理渲染管线
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.context];
        
    [self createTerrain];
}

#pragma mark -- resource load
- (void)createTerrain {
    UIImage *heightMapImg = [UIImage imageNamed:@"terrain_01.jpg"];
    UIImage *grassImg = [UIImage imageNamed:@"grass_01.jpg"];
    UIImage *dirtImg = [UIImage imageNamed:@"dirt_01.jpg"];
    
    self.heightMap = heightMapImg;
    self.terrainSize = CGSizeMake(500, 500);
    self.terrainHeight = 100;
        
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"vertex" ofType:@".glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"frag_laser" ofType:@".glsl"];
    GLContext *terrainContext = [GLContext contextWithVertexShaderPath:vertexShaderPath fragmentShaderPath:fragmentShaderPath];
    self.glContext = terrainContext;
    
    GLKTextureInfo *grass = [GLKTextureLoader textureWithCGImage:grassImg.CGImage options:nil error:nil];
    NSError *error;
    GLKTextureInfo *dirt = [GLKTextureLoader textureWithCGImage:dirtImg.CGImage options:nil error:&error];
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, grass.name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glBindTexture(GL_TEXTURE_2D, dirt.name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    
    GLfloat offset = self.terrainSize.width/2.0;
    Terrain *terrain = [[Terrain alloc] initWithGLContext:terrainContext heightMap:heightMapImg size:self.terrainSize height:self.terrainHeight grass:grass dirt:dirt];
    terrain.modelMatrix = GLKMatrix4MakeTranslation(-offset, 0, -offset);
    [self.objects addObject:terrain];
}

- (GLubyte *)dataFromImage:(UIImage *)img {
    CGImageRef imageRef = [img CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    GLubyte *textureData = (GLubyte *)malloc(width * height * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(textureData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    return textureData;
}

- (GLKVector3)vertexPosition:(int)col row:(int)row buffer:(unsigned char *)buffer bytesPerRow:(size_t)bytesPerRow bytesPerPixel:(size_t)bytesPerPixel {
    long long offset = (int)(row / self.terrainSize.height * self.heightMap.size.height) * bytesPerRow + (int)(col / self.terrainSize.width * self.heightMap.size.width) * bytesPerPixel;
    unsigned char r = buffer[offset];
    GLfloat x = col;
    GLfloat y = r / 255.0 * self.terrainHeight;
    GLfloat z = row;
    return GLKVector3Make(x, y, z);
}

- (GLKVector3)vertexNormal:(GLKVector3)position col:(int)col row:(int)row buffer:(unsigned char *)buffer bytesPerRow:(size_t)bytesPerRow bytesPerPixel:(size_t)bytesPerPixel {
    GLKVector3 sides[4]; // 最多四条共享边
    int sideCount = 0;
    // 统计顶点有几条共享边，从而计算法线
    if (col >= 1) {
        //左边有共享边
        GLKVector3 leftPosition = [self vertexPosition:col - 1 row:row buffer:buffer bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel];
        GLKVector3 vectorLeft = GLKVector3Subtract(leftPosition, position);
        sides[sideCount] = vectorLeft;
        sideCount++;
    }
    if (row >= 1) {
        //前面有共享边
        GLKVector3 frontPosition = [self vertexPosition:col row:row - 1 buffer:buffer bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel];
        GLKVector3 vectorFront = GLKVector3Subtract(frontPosition, position);
        sides[sideCount] = vectorFront;
        sideCount++;
    }
    if (col <= self.terrainSize.width - 1) {
        //右边有共享边
        GLKVector3 rightPosition = [self vertexPosition:col + 1 row:row buffer:buffer bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel];
        GLKVector3 vectorRight = GLKVector3Subtract(rightPosition, position);
        sides[sideCount] = vectorRight;
        sideCount++;
    }
    if (row <= self.terrainSize.width - 1) {
        //后面有共享边
        GLKVector3 backPosition = [self vertexPosition:col row:row + 1 buffer:buffer bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel];
        GLKVector3 vectorBack = GLKVector3Subtract(backPosition, position);
        sides[sideCount] = vectorBack;
        sideCount++;
    }
    
    GLKVector3 normal = GLKVector3Make(0, 0, 0);
    for (int i = 0; i < sideCount; ++i) {
        GLKVector3 vec = sides[i];
        if (i == sideCount - 1 && i != 3) {
            continue;
        }
        GLKVector3 vec2 = i == sideCount - 1 ? sides[0] : sides[i + 1];
        normal = GLKVector3Add(normal, GLKVector3CrossProduct(vec2, vec));
    }
    return GLKVector3Normalize(normal);
}

- (void)buildGeometry {
    CGImageRef image = self.heightMap.CGImage;
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
    size_t bitesPerPixel = CGImageGetBitsPerPixel(image);
    size_t bytesPerPixel = bitesPerPixel / bitsPerComponent;
    UInt8 * buffer = [self dataFromImage:self.heightMap];
    for (int row = 0;row < self.terrainSize.height; ++row) {
        GLGeometry * terrainMeshStrip = [[GLGeometry alloc] initWithGeometryType:GLGeometryTypeTriangleStrip];
        for (int col = 0;col <= self.terrainSize.width; ++col) {
            GLKVector3 position1 = [self vertexPosition:col row:row buffer:buffer bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel];
            GLKVector3 normal1 = [self vertexNormal:position1 col:col row:row buffer:buffer bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel];
            GLVertex vertex1 = GLVertexMake(position1.x, position1.y, position1.z, normal1.x, normal1.y, normal1.z, col / (GLfloat)self.terrainSize.width * 2, row / (GLfloat)self.terrainSize.height * 2);
            [terrainMeshStrip appendVertex:vertex1];
            
            GLKVector3 position2 = [self vertexPosition:col row:row + 1 buffer:buffer bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel];
            GLKVector3 normal2 = [self vertexNormal:position2 col:col row:row + 1 buffer:buffer bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel];
            GLVertex vertex2 = GLVertexMake(position2.x, position2.y, position2.z, normal2.x, normal2.y, normal2.z, col / (GLfloat)self.terrainSize.width * 2, (row + 1) / (GLfloat)self.terrainSize.height * 2) ;
            [terrainMeshStrip appendVertex:vertex2];
        }
        [self.terrainMeshStrips addObject:terrainMeshStrip];
    }
    free(buffer);
}


#pragma mark -- system call

- (void)update {
    // 距离上一次调用update过了多长时间，比如一个游戏物体速度是3m/s,那么每一次调用update，
    // 他就会行走3m/s * deltaTime，这样做就可以让游戏物体的行走实际速度与update调用频次无关
    NSTimeInterval deltaTime = self.timeSinceLastUpdate;
    self.elapsedTime += deltaTime;
    
    float varyingFactor = (sin(self.elapsedTime) + 1) / 2.0; // 0 ~ 1
    varyingFactor = -0.7;
    self.cameraMatrix = GLKMatrix4MakeLookAt(0, 0, 2 * (varyingFactor + 1), 0, 0, 0, 0, 1, 0);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    // 清空之前的绘制
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    [self.glContext active];
    GLuint program = self.glContext.program;
    // 使用fragment.glsl 和 vertex.glsl中的shader
    
    // 设置shader中的 uniform elapsedTime 的值
    GLuint elapsedTimeUniformLocation = glGetUniformLocation(program, "elapsedTime");
    glUniform1f(elapsedTimeUniformLocation, (GLfloat)self.elapsedTime);
    
    GLuint projectionMatrixUniformLocation = glGetUniformLocation(program, "projectionMatrix");
    glUniformMatrix4fv(projectionMatrixUniformLocation, 1, 0, self.projectionMatrix.m);
    GLuint cameraMatrixUniformLocation = glGetUniformLocation(program, "cameraMatrix");
    glUniformMatrix4fv(cameraMatrixUniformLocation, 1, 0, self.cameraMatrix.m);

    for (Terrain *ter in self.objects) {
        [ter draw:self.glContext];
    }
}
@end
