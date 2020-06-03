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

@interface ViewController ()<GLKViewDelegate>
@property (strong, nonatomic) EAGLContext *context;

@property(nonatomic,strong)GLContext *glContext;
@property (assign, nonatomic)GLfloat elapsedTime;

@property (assign, nonatomic) GLKMatrix4 transformMatrix;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.transformMatrix = GLKMatrix4Identity;
    
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

#define UsePerspective // 注释这行运行查看正交投影效果，解除注释运行查看透视投影效果

- (void)update {
    // 距离上一次调用update过了多长时间，比如一个游戏物体速度是3m/s,那么每一次调用update，
    // 他就会行走3m/s * deltaTime，这样做就可以让游戏物体的行走实际速度与update调用频次无关
    NSTimeInterval deltaTime = self.timeSinceLastUpdate;
    self.elapsedTime += deltaTime;
    
    float varyingFactor = self.elapsedTime;
    
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(varyingFactor, 0, 1, 0);
    
#ifdef UsePerspective
    /*
     GLKit提供了GLKMatrix4MakePerspective方法便捷的生成透视投影矩阵。
     方法有4个参数float fovyRadians, float aspect, float nearZ, float farZ。
     fovyRadians表示视角。
     aspect表示屏幕宽高比，为了将所有轴的单位长度统一，所以需要知道屏幕宽高比多少。
     nearZ表示可视范围在Z轴的起点到原点(0,0,0)的距离，
     farZ表示可视范围在Z轴的终点到原点(0,0,0)的距离,nearZ和farZ始终为正。
     */
    /*
     根据上面的条件，一个位于z=0上的点是不能被投影到屏幕的，
     所以我增加了一个平移矩阵GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(0, 0, -1.6),
     为了演示近大远小的视觉效果，我又增加了旋转矩阵GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(varyingFactor, 0, 1, 0)。
     最后将 perspectiveMatrix * translateMatrix * rotateMatrix的结果赋值给Vertex Shader中的transform。
     */
    // 透视投影
    int offset = -30;
    float aspect = self.view.frame.size.width / self.view.frame.size.height;
    GLKMatrix4 perspectiveMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90 + offset), aspect, 0.1, 10.0);
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(0, 0, -1.6);
    
    self.transformMatrix = GLKMatrix4Multiply(translateMatrix, rotateMatrix);
    self.transformMatrix = GLKMatrix4Multiply(perspectiveMatrix, self.transformMatrix);
#else
    /*
     正交投影其实比较好理解，原先屏幕的X轴从左到右是-1到1，Y轴从上到下是1到-1，
     经过GLKMatrix4 orthMatrix = GLKMatrix4MakeOrtho(-viewWidth/2, viewWidth/2, -viewHeight / 2, viewHeight/2, -10, 10)正交矩阵的变换，
     就会变成X轴从左到右是-viewWidth/2到viewWidth/2，Y轴从上到下是viewHeight/2到-viewHeight / 2，
     viewWidth和viewHeight是屏幕的宽和高。
     我增加了一个缩放矩阵GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(200, 200, 200)，是为了可以看见渲染出来的矩形。
     因为它原本只有1 x 1的大小，在正交投影后，也就是一个像素的大小，几乎是看不见的。
     正交投影里的nearZ和farZ代表可视的Z轴范围，超出的点就不可见了。
     */
    // 正交投影
    float viewWidth = self.view.frame.size.width;
    float viewHeight = self.view.frame.size.height;
    GLKMatrix4 orthMatrix = GLKMatrix4MakeOrtho(-viewWidth/2, viewWidth/2, -viewHeight / 2, viewHeight/2, -10, 10);
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(200, 200, 200);
    self.transformMatrix = GLKMatrix4Multiply(scaleMatrix, rotateMatrix);
    self.transformMatrix = GLKMatrix4Multiply(orthMatrix, self.transformMatrix);
#endif
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    // 清空之前的绘制
    glClearColor(1, 0.2, 0.2, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    GLuint program = self.glContext.program;
    
    // 使用fragment.glsl 和 vertex.glsl中的shader
    glUseProgram(program);
    // 设置shader中的 uniform elapsedTime 的值
    GLuint elapsedTimeUniformLocation = glGetUniformLocation(program, "elapsedTime");
    glUniform1f(elapsedTimeUniformLocation, (GLfloat)self.elapsedTime);
    
    
    GLuint transformUniformLocation = glGetUniformLocation(program, "transform");
    glUniformMatrix4fv(transformUniformLocation, 1, 0, self.transformMatrix.m);
    [self drawTriangle];
}
#pragma mark -- 绘制功能

/** 根据顶点、颜色绘制三角形
 */
- (void)drawTriangle {
    static GLfloat triangleData[36] = {
        -0.5,   0.5f,  0,   1,  0,  0, // x, y, z, r, g, b,每一行存储一个点的信息，位置和颜色
        -0.5f,  -0.5f,  0,  0,  1,  0,
        0.5f,   -0.5f,  0,  0,  0,  1,
        0.5,    -0.5f, 0,   0,  0,  1,
        0.5f,  0.5f,  0,    0,  1,  0,
        -0.5f,   0.5f,  0,  1,  0,  0,
    };
    [self bindAttribs:triangleData];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
