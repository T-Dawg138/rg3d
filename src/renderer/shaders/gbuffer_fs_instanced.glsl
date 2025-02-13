#version 330 core

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outAmbient;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;
uniform sampler2D specularTexture;
uniform sampler2D lightmapTexture;
uniform sampler2D roughnessTexture;
uniform sampler2D heightTexture;
uniform samplerCube environmentMap;
uniform vec3 cameraPosition;
uniform bool usePOM;

in vec3 position;
in vec3 normal;
in vec2 texCoord;
in vec3 tangent;
in vec3 binormal;
in vec2 secondTexCoord;
in vec4 diffuseColor;

void main()
{
    mat3 tangentSpace = mat3(tangent, binormal, normal);
    vec3 toFragment = normalize(position - cameraPosition);

    vec2 tc;
    if (usePOM) {
        vec3 toFragmentTangentSpace = normalize(transpose(tangentSpace) * toFragment);
        tc = S_ComputeParallaxTextureCoordinates(heightTexture, toFragmentTangentSpace, texCoord, normal);
    } else {
        tc = texCoord;
    }

    outColor = diffuseColor * texture(diffuseTexture, tc);
    if (outColor.a < 0.5) {
        discard;
    }
    outColor.a = 1.0;
    vec4 n = normalize(texture(normalTexture, tc) * 2.0 - 1.0);
    outNormal.xyz = normalize(tangentSpace * n.xyz) * 0.5 + 0.5;
    outNormal.w = texture(specularTexture, tc).r;
    outAmbient = vec4(texture(lightmapTexture, secondTexCoord).rgb, 1.0);

    // reflection mapping
    float roughness = texture(roughnessTexture, tc).r;
    vec3 reflectionTexCoord = reflect(toFragment, normalize(n.xyz));
    outColor = (1.0 - roughness) * outColor + roughness * vec4(texture(environmentMap, reflectionTexCoord).rgb, outColor.a);
}
