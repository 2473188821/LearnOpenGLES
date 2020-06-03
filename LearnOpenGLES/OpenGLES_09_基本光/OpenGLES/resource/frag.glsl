
precision highp float;

varying vec3 fragNormal;

uniform float elapsedTime;
uniform vec3 lightDirection;
uniform mat4 normalMatrix;

void main(void) {
    /* 因为光线是照射到平面的方向，而法线是从平面往外的方向，所以他们相乘之前需要把光照方向反过来，并且要规范化。 */
    vec3 normalizedLightDirection = normalize(-lightDirection);
    vec3 transformedNormal = normalize((normalMatrix * vec4(fragNormal, 1.0)).xyz);
    /** 漫反射强度 */
    float diffuseStrength = dot(normalizedLightDirection, transformedNormal);
    diffuseStrength = clamp(diffuseStrength, 0.0, 1.0);
    vec3 diffuse = vec3(diffuseStrength);
    /** 环境光强度 */
    vec3 ambient = vec3(0.3);
    /** 环境光强度加上漫反射强度就是最后的光照强度finalLightStrength了 */
    vec4 finalLightStrength = vec4(ambient + diffuse, 1.0);
    /** 材质颜色 */
    vec4 materialColor = vec4(1.0, 0.0, 0.0, 1.0);
    
    /** 光照强度乘以材质本身的颜色materialColor得到最终的颜色，这里材质本身的颜色我用的是红色 */
    gl_FragColor = finalLightStrength * materialColor;
}

