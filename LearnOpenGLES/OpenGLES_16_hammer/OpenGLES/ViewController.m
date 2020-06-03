//
//  ViewController.m
//  OpenGLES
//
//  Created by Chenfy on 2020/5/17.
//  Copyright © 2020 Chenfy. All rights reserved.
//

#import "ViewController.h"
#import "GLContext.h"
#import "Cylinder.h"

#define KLogFun NSLog(@"__func___:%s",__func__)

@interface ViewController ()<GLKViewDelegate>
@property (assign, nonatomic)GLfloat         elapsedTime;
@property (strong, nonatomic)EAGLContext     *context;
@property (nonatomic, strong)GLContext      *glContext;
@property (nonatomic, strong)NSMutableArray *objects;


@property (strong, nonatomic) GLKTextureInfo *difuseMap;
@property (strong, nonatomic) GLKTextureInfo *normalMap;

@property (assign, nonatomic) GLKMatrix4 projectionMatrix; // 投影矩阵
@property (assign, nonatomic) GLKMatrix4 cameraMatrix; // 观察矩阵
@property (assign, nonatomic) GLKMatrix4 modelMatrix; // 矩形的模型变换
@end

@implementation ViewController

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
    
    /** 编译、链接、激活着色器 */
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"ver" ofType:@".glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"frag" ofType:@".glsl"];
    self.glContext = [GLContext contextWithVertexShaderPath:vertexShaderPath fragmentShaderPath:fragmentShaderPath];
    
    NSString *redS = [[NSBundle mainBundle] pathForResource:@"texture" ofType:@"jpg"];
    NSString *greenS = [[NSBundle mainBundle] pathForResource:@"green" ofType:@"png"];
    NSError *error;
    self.difuseMap = [GLKTextureLoader textureWithContentsOfFile:redS options:nil error:&error];
    self.normalMap = [GLKTextureLoader textureWithContentsOfFile:greenS options:nil error:&error];
    
    [self createCylinder];
}

- (void)update {
    // 距离上一次调用update过了多长时间，比如一个游戏物体速度是3m/s,那么每一次调用update，
    // 他就会行走3m/s * deltaTime，这样做就可以让游戏物体的行走实际速度与update调用频次无关
    NSTimeInterval deltaTime = self.timeSinceLastUpdate;
    self.elapsedTime += deltaTime;
    
    float varyingFactor = (sin(self.elapsedTime) + 1) / 2.0; // 0 ~ 1
    self.cameraMatrix = GLKMatrix4MakeLookAt(0, 0, 2 * (varyingFactor + 1), 0, 0, 0, 0, 1, 0);

    for (Cylinder  *lind in self.objects) {
           [lind update:self.elapsedTime];
    }
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
    
    for (Cylinder  *lind in self.objects) {
        [lind draw:self.glContext];
    }
}

- (void)createCylinder {
    UIImage *img1 = [UIImage imageNamed:@"metal_01.png"];
    UIImage *img2 = [UIImage imageNamed:@"metal_02.png"];
    UIImage *img3 = [UIImage imageNamed:@"metal_03.png"];

    GLKTextureInfo *metal1 = [GLKTextureLoader textureWithCGImage:img1.CGImage options:nil error:nil];
    GLKTextureInfo *metal2 = [GLKTextureLoader textureWithCGImage:img2.CGImage options:nil error:nil];
    GLKTextureInfo *metal3 = [GLKTextureLoader textureWithCGImage:img3.CGImage options:nil error:nil];
    // 四边的圆柱体就是一个四方体
    Cylinder * cylinder = [[Cylinder alloc] initWithGLContext:self.glContext sides:4 radius:0.9 height:1.2 texture:metal1];
    cylinder.modelMatrix = GLKMatrix4MakeTranslation(0, 2, 0);
    [self.objects addObject:cylinder];
    
    Cylinder * cylinder2 = [[Cylinder alloc] initWithGLContext:self.glContext sides:16 radius:0.2 height:4.0 texture:metal3];
    [self.objects addObject:cylinder2];
    
    // 四边的圆柱体就是一个正方体
    Cylinder * cylinder3 = [[Cylinder alloc] initWithGLContext:self.glContext sides:4 radius:0.41 height:0.3 texture:metal2];
    cylinder3.modelMatrix = GLKMatrix4MakeTranslation(0, -2, 0);
    [self.objects addObject:cylinder3];
}

- (NSMutableArray *)objects {
    if (!_objects) {
        _objects = [NSMutableArray array];
    }
    return _objects;
}

@end