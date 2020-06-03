//
//  ViewController.m
//  OpenGLES
//
//  Created by Chenfy on 2020/5/17.
//  Copyright © 2020 Chenfy. All rights reserved.
//

#import "ViewController.h"
#import "GLContext.h"

#define KLogFun NSLog(@"__func___:%s",__func__)

/*** MVP 
 MVP表示的是模型矩阵（Model），观察矩阵（View），投影矩阵（Projection）。
 投影矩阵介绍过了。
 模型矩阵针对的是单个3D模型，渲染每一个3D模型前，需要将各自的模型矩阵传递给Vertex Shader。
 观察矩阵针对的是场景中的所有物体，当观察矩阵改变时，所有顶点的位置都会受到影响，就好像你移动现实世界的摄像机，拍摄到的场景就会变化一样。
 
 所以观察矩阵可以理解为OpenGL 3D世界中的摄像机。
 我们有了摄像机这个变换矩阵之后，就可以很方便的在3D世界中游览，就像第一人称视角游戏中一样。
 */

/*
 我将之前的属性transform换成了4个变换矩阵，分别是两个M和VP。
 本文的例子将绘制两个矩形，所以我为它们分别定义了模型矩阵modelMatrix1和modelMatrix2。
 */
@interface ViewController ()<GLKViewDelegate>
@property (strong, nonatomic) EAGLContext *context;

@property(nonatomic,strong)GLContext *glContext;
@property (assign, nonatomic)GLfloat elapsedTime;

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
    
    /*
     投影矩阵使用了透视投影进行初始化。
     两个模型矩阵初始化为单位矩阵。
     本文的主角观察矩阵初始化为摄像机在 0，0，2 坐标，看向 0，0，0点，向上朝向0，1，0。
     GLKMatrix4MakeLookAt提供了快捷创建观察矩阵的方法，需要传递9个参数:
     摄像机的位置eyeX，eyeY，eyeZ，摄像机看向的点centerX，centerY，centerZ，摄像机向上的朝向upX, upY, upZ。
     改变这几个参数就能控制摄像机在3D世界中通过不同角度拍摄物体。
     */
    // 设置摄像机在 0，0，2 坐标，看向 0，0，0点。Y轴正向为摄像机顶部指向的方向
    self.cameraMatrix = GLKMatrix4MakeLookAt(0, 0, 2, 0, 0, 0, 0, 1, 0);
    
    // 先初始化矩形的模型矩阵为单位矩阵
    self.modelMatrix = GLKMatrix4Identity;
    
    [self setupContext];
    [self setupGLContext];
    
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
}

/** 编译、链接、激活着色器
 */
- (void)setupGLContext {
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"ver" ofType:@".glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"frag" ofType:@".glsl"];
    self.glContext = [GLContext contextWithVertexShaderPath:vertexShaderPath fragmentShaderPath:fragmentShaderPath];
}

#pragma mark -- System call
- (void)bindAttribs:(GLfloat *)triangleData {
    // 启用Shader中的两个属性
    // attribute vec4 position;
    // attribute vec4 color;
    GLuint program = self.glContext.program;
    
    GLuint positionAttribLocation = glGetAttribLocation(program, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    GLuint colorAttribLocation = glGetAttribLocation(program, "color");
    glEnableVertexAttribArray(colorAttribLocation);
    
    // 为shader中的position和color赋值
    // glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)
    // indx: 上面Get到的Location
    // size: 有几个类型为type的数据，比如位置有x,y,z三个GLfloat元素，值就为3
    // type: 一般就是数组里元素数据的类型
    // normalized: 暂时用不上
    // stride: 每一个点包含几个byte，本例中就是6个GLfloat，x,y,z,r,g,b
    // ptr: 数据开始的指针，位置就是从头开始，颜色则跳过3个GLFloat的大小
    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)triangleData);
    glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)triangleData + 3 * sizeof(GLfloat));
}


- (void)update {
    // 距离上一次调用update过了多长时间，比如一个游戏物体速度是3m/s,那么每一次调用update，
    // 他就会行走3m/s * deltaTime，这样做就可以让游戏物体的行走实际速度与update调用频次无关
    NSTimeInterval deltaTime = self.timeSinceLastUpdate;
    self.elapsedTime += deltaTime;
    
    float varyingFactor = (sin(self.elapsedTime) + 1) / 2.0; // 0 ~ 1
    self.cameraMatrix = GLKMatrix4MakeLookAt(0, 0, 2 * (varyingFactor + 1), 0, 0, 0, 0, 1, 0);
    
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(varyingFactor * M_PI * 2, 1, 1, 1);
    self.modelMatrix = rotateMatrix;
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    // 清空之前的绘制
    glClearColor(0.2, 0.2, 0.2, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    GLuint program = self.glContext.program;
    // 使用fragment.glsl 和 vertex.glsl中的shader
    glUseProgram(program);
    
    // 设置shader中的 uniform elapsedTime 的值
    GLuint elapsedTimeUniformLocation = glGetUniformLocation(program, "elapsedTime");
    glUniform1f(elapsedTimeUniformLocation, (GLfloat)self.elapsedTime);
    
    GLuint projectionMatrixUniformLocation = glGetUniformLocation(program, "projectionMatrix");
    glUniformMatrix4fv(projectionMatrixUniformLocation, 1, 0, self.projectionMatrix.m);
    GLuint cameraMatrixUniformLocation = glGetUniformLocation(program, "cameraMatrix");
    glUniformMatrix4fv(cameraMatrixUniformLocation, 1, 0, self.cameraMatrix.m);
    
    GLuint modelMatrixUniformLocation = glGetUniformLocation(program, "modelMatrix");
    glUniformMatrix4fv(modelMatrixUniformLocation, 1, 0, self.modelMatrix.m);
    [self drawCube];
}


#pragma mark -- 绘制功能

/** 根据顶点、颜色绘制cube
 */
- (void)drawCube {
    [self drawXPlanes];
    [self drawYPlanes];
    [self drawZPlanes];
}

- (void)drawZPlanes {
    static GLfloat triangleData[] = {
        -0.5,   0.5f,  0.5,   0,  0,  1,
        -0.5f,  -0.5f,  0.5,  0,  0,  1,
        0.5f,   -0.5f,  0.5,  0,  0,  1,
        0.5,    -0.5f, 0.5,   0,  0,  1,
        0.5f,  0.5f,  0.5,    0,  0,  1,
        -0.5f,   0.5f,  0.5,  0,  0,  1,
        -0.5,   0.5f,  -0.5,   0,  0,  1,
        -0.5f,  -0.5f,  -0.5,  0,  0,  1,
        0.5f,   -0.5f,  -0.5,  0,  0,  1,
        0.5,    -0.5f, -0.5,   0,  0,  1,
        0.5f,  0.5f,  -0.5,    0,  0,  1,
        -0.5f,   0.5f,  -0.5,  0,  0,  1,
    };
    [self bindAttribs:triangleData];
    glDrawArrays(GL_TRIANGLES, 0, 12);
}

- (void)drawXPlanes {
    static GLfloat triangleData[] = {
        // X轴0.5处的平面
        0.5,  -0.5,    0.5f, 1,  0,  0,
        0.5,  -0.5f,  -0.5f, 1,  0,  0,
        0.5,  0.5f,   -0.5f, 1,  0,  0,
        0.5,  0.5,    -0.5f, 1,  0,  0,
        0.5,  0.5f,    0.5f, 1,  0,  0,
        0.5,  -0.5f,   0.5f, 1,  0,  0,
        // X轴-0.5处的平面
        -0.5,  -0.5,    0.5f, 1,  0,  0,
        -0.5,  -0.5f,  -0.5f, 1,  0,  0,
        -0.5,  0.5f,   -0.5f, 1,  0,  0,
        -0.5,  0.5,    -0.5f, 1,  0,  0,
        -0.5,  0.5f,    0.5f, 1,  0,  0,
        -0.5,  -0.5f,   0.5f, 1,  0,  0,
    };
    [self bindAttribs:triangleData];
    glDrawArrays(GL_TRIANGLES, 0, 12);
}

- (void)drawYPlanes {
    static GLfloat triangleData[] = {
        -0.5,  0.5,  0.5f, 0,  1,  0,
        -0.5f, 0.5, -0.5f, 0,  1,  0,
        0.5f, 0.5,  -0.5f, 0,  1,  0,
        0.5,  0.5,  -0.5f, 0,  1,  0,
        0.5f, 0.5,   0.5f, 0,  1,  0,
        -0.5f, 0.5,  0.5f, 0,  1,  0,
        -0.5, -0.5,   0.5f, 0,  1,  0,
        -0.5f, -0.5, -0.5f, 0,  1,  0,
        0.5f, -0.5,  -0.5f, 0,  1,  0,
        0.5,  -0.5,  -0.5f, 0,  1,  0,
        0.5f, -0.5,   0.5f, 0,  1,  0,
        -0.5f, -0.5,  0.5f, 0,  1,  0,
    };
    [self bindAttribs:triangleData];
    glDrawArrays(GL_TRIANGLES, 0, 12);
}

@end
