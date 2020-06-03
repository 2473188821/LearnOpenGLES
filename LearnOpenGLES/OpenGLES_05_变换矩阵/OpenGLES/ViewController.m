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

- (void)update {
    // 距离上一次调用update过了多长时间，比如一个游戏物体速度是3m/s,那么每一次调用update，
    // 他就会行走3m/s * deltaTime，这样做就可以让游戏物体的行走实际速度与update调用频次无关
    NSTimeInterval deltaTime = self.timeSinceLastUpdate;
    self.elapsedTime += deltaTime;
    
    float varyingFactor = sin(self.elapsedTime);
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(varyingFactor, varyingFactor, 1.0);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(varyingFactor , 0.0, 0.0, 1.0);
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(varyingFactor, 0.0, 0.0);
    
    // transformMatrix = translateMatrix * rotateMatrix * scaleMatrix
    // 矩阵会按照从右到左的顺序应用到position上。也就是先缩放（scale）,再旋转（rotate）,最后平移（translate）
    // 如果这个顺序反过来，就完全不同了。从线性代数角度来讲，就是矩阵A乘以矩阵B不等于矩阵B乘以矩阵A。
    self.transformMatrix = GLKMatrix4Multiply(translateMatrix, rotateMatrix);
    self.transformMatrix = GLKMatrix4Multiply(self.transformMatrix, scaleMatrix);
    
    /** Test transform effect
    self.transformMatrix = translateMatrix;
    self.transformMatrix = rotateMatrix;
    self.transformMatrix = scaleMatrix;
    */
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
        0,      0.5f,  0,  1,  0,  0, // x, y, z, r, g, b,每一行存储一个点的信息，位置和颜色
        -0.5f,  0.0f,  0,  0,  1,  0,
        0.5f,   0.0f,  0,  0,  0,  1,
        0,      -0.5f,  0,  1,  0,  0,
        -0.5f,  0.0f,  0,  0,  1,  0,
        0.5f,   0.0f,  0,  0,  0,  1,
    };
    [self bindAttribs:triangleData];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
