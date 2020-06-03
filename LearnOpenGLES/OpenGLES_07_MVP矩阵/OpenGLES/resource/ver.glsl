
/*
 我把之前的uniform transform换成了
 三个变换矩阵projectionMatrix,cameraMatrix,modelMatrix,它们分别是投影矩阵，观察矩阵，模型矩阵。
 将它们相乘projectionMatrix * cameraMatrix * modelMatrix，结果乘以position赋值给gl_Position。
 
 注意相乘的顺序，这个顺序的结果是先进行模型矩阵变换，再是观察矩阵，最后是投影矩阵变换。
 这样Vertex Shader中的MVP就实现完了，很简单是不是。
 */

attribute vec4 position;
attribute vec4 color;

uniform float elapsedTime;

uniform mat4 projectionMatrix;
uniform mat4 cameraMatrix;
uniform mat4 modelMatrix;

varying vec4 fragColor;

void main(void) {
    fragColor = color;
    mat4 mvp = projectionMatrix * cameraMatrix * modelMatrix;
    gl_Position = mvp * position;
}
