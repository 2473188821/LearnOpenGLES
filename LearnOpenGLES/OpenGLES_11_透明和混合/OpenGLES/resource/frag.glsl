

precision highp float;

varying vec3 fragNormal;
varying vec2 fragUV;

uniform float elapsedTime;
uniform vec3 lightDirection;
uniform mat4 normalMatrix;
uniform sampler2D diffuseMap;

void main(void) {
    /*
    因为光线是照射到平面的方向，而法线是从平面往外的方向，所以他们相乘之前需要把光照方向反过来，并且要规范化。
     */
    vec3 normalizedLightDirection = normalize(-lightDirection);
    vec3 transformedNormal = normalize((normalMatrix * vec4(fragNormal, 1.0)).xyz);
    
    float diffuseStrength = dot(normalizedLightDirection, transformedNormal);
    diffuseStrength = clamp(diffuseStrength, 0.0, 1.0);
    vec3 diffuse = vec3(diffuseStrength);
    
    vec3 ambient = vec3(0.3);
    
    vec4 finalLightStrength = vec4(ambient + diffuse, 1.0);    
    vec4 materialColor = texture2D(diffuseMap, fragUV);

    gl_FragColor = finalLightStrength * materialColor;
}

