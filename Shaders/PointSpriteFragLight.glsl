////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (c) 2018 Michele Morrone
//  All rights reserved.
//
//  mailto:me@michelemorrone.eu
//  mailto:brutpitt@gmail.com
//  
//  https://github.com/BrutPitt
//
//  https://michelemorrone.eu
//  https://BrutPitt.com
//
//  This software is distributed under the terms of the BSD 2-Clause license:
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//   
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF 
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
////////////////////////////////////////////////////////////////////////////////

// #version dynamically inserted
layout(std140) uniform;

LAYUOT_BINDING(1) uniform sampler2D tex;
uniform vec2 WinAspect;

subroutine vec4 _pixelColor();

LAYUOT_BINDING(2) uniform _particlesData {
    float lightDiffInt;
    float lightSpecInt;
    float lightAmbInt ;
    float lightShinExp;
    vec3 lightDir;
    float sstepColorMin;
    float sstepColorMax;
    float pointSize;
    float pointDistAtten;
    float alphaDistAtten;
    float alphaSkip;
    float alphaK;
    float clippingDist;
    float zFar;
    float velIntensity;
} u;

//#define _LIGHT_



//uniform vec3 light;
in vec3 posEye;
in vec4 LightRay;
in float pointSZ;


in float pointDistance;
in vec4 particleColor;
out vec4 outColor;

//uniform float distAlphaFactor;
//uniform float alphaK;

// in OGL 4.5 "cull distance" to drop Vertex... to look in upgrade

float getAlpha(float alpha)
{

    CONST float alphaAtten = exp(-0.1*pow(pointDistance+1.f, u.alphaDistAtten*.1));
    return clamp(alpha*alpha * alphaAtten * u.alphaK, 0.0, 1.0);

}

float getSpotSpecular(vec3 N)
{
// point on surface of sphere in eye space
    vec3 spherePosEye = posEye + N*pointSZ;

	vec3 v = normalize(-spherePosEye);
    vec3 h = normalize(LightRay.xyz + v);
    return pow(max(0.0, dot(N, h)), u.lightShinExp);
}

float getParallelSpecular(vec3 N)
{
// point on surface of sphere in eye space
    vec3 spherePosEye = N*pointSZ;

	vec3 v = normalize(spherePosEye);
    vec3 h = normalize(LightRay.xyz + v);
    return pow(max(0.0, dot(N, h)), u.lightShinExp);
}

CONST float LOG2 = 1.442695;

LAYUOT_INDEX(1) subroutine(_pixelColor) vec4 pixelColorLight()
{
    vec3 N;

   CONST float texVal = texture(tex, gl_PointCoord).r;
    vec4 color = particleColor * texVal;

    float alpha = getAlpha(color.a);

    N.xy = gl_PointCoord-vec2(.5);
    //N = vec3(vec2(gl_PointCoord.x-.5, -gl_PointCoord.y+.5), texVal); // xy = radius in 0, z = magnitudo
    //N.z = texVal;   //Using texIntensityVal, sastest, instead: N.z = sqrt(1.0-mag);

    float mag = dot(N.xy, N.xy);
    if (mag > .25f || alpha < u.alphaSkip) discard;   // kill pixels outside circle: r=.5
    
    N.z = sqrt(1.0-mag);
    N = normalize(N);
    
    //float val = ;    
    float diffuse = max(0.0, dot((LightRay.xyz), N)); //LightRay.xyz normalized in VS

    float specular = getSpotSpecular(N);



    vec3 lColor =  smoothstep(u.sstepColorMin, u.sstepColorMax,
                                (color.rgb * diffuse *u.lightDiffInt + 
                                vec3(specular) *u.lightSpecInt     + 
                                (color.rgb+u.lightAmbInt*0.1) * u.lightAmbInt)); /*+ color.rgb * (1.0 - negDiffuse)+ color.rgb * ambient + vec3(specular) * .6*/
 
    vec4 col = vec4(lColor.rgb , alpha);

    //float alphaAtten = (color.a)/(pow(length(posEye),distAlphaFactor));
    //gl_FragColor = vec4(color.rgb , min(color.a*alphaK,alphaAtten)); 
     return  col;        

}

LAYUOT_INDEX(0) subroutine(_pixelColor)  vec4 pixelColorOnly()
{

    vec4 color = particleColor * texture(tex, gl_PointCoord).r;
    
    float alpha = getAlpha(color.a);
    if(alpha < u.alphaSkip ) discard ;

    return vec4(color.rgb , alpha);

}

subroutine uniform _pixelColor pixelColor;

void main()
{

    gl_FragDepth = -posEye.z*u.zFar;
    //outColor = vec4(vec3((gl_FragDepth)), 1.f);

    outColor = pixelColor();
}
