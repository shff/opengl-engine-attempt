#import <OpenGL/gl.h>
#import <math.h>

// #define GLSL(str) (const char *)"#version 330\n" #str

typedef struct
{
  float x, y, z;
} vector;

typedef struct
{
  float m[16];
} matrix;

matrix getProjectionMatrix(int w, int h)
{
  float fov = 65.0f;
  float aspect = (float)w / (float)h;
  float near = 1.0f;
  float far = 1000.0f;

  return (matrix){
      .m = {[0] = 1.0f / (aspect * tanf(fov * 3.14f / 180.0f / 2.0f)),
            [5] = 1.0f / tanf(fov * 3.14f / 180.0f / 2.0f),
            [10] = -(far + near) / (far - near), [11] = -1.0f,
            [14] = -(2.0f * far * near) / (far - near)}};
}

matrix getViewMatrix(float x, float y, float z, float a, float p)
{
  float cosy = cosf(a), siny = sinf(a), cosp = cosf(p), sinp = sinf(p);

  return (matrix){
      .m = {
              [0] = cosy, [1] = siny * sinp, [2] = siny * cosp, [5] = cosp,
              [6] = -sinp, [8] = -siny, [9] = cosy * sinp, [10] = cosp * cosy,
              [12] = -(cosy * x - siny * z),
              [13] = -(siny * sinp * x + cosp * y + cosy * sinp * z),
              [14] = -(siny * cosp * x - sinp * y + cosp * cosy * z),
              [15] = 1.0f,
      }};
}

unsigned int makeShader(const char *shaderCode, const unsigned int shaderType)
{
  // Compile a Shader
  unsigned int shader = glCreateShader(shaderType);
  glShaderSource(shader, 1, &shaderCode, 0);
  glCompileShader(shader);
  return shader;
}

unsigned int makeProgram(const char *vertexCode, const char *fragCode)
{
  // Compile Shaders
  unsigned int vertShader = makeShader(vertexCode, GL_VERTEX_SHADER);
  unsigned int fragShader = makeShader(fragCode, GL_FRAGMENT_SHADER);

  // Link the program
  unsigned int program = glCreateProgram();
  glAttachShader(program, vertShader);
  glAttachShader(program, fragShader);
  glLinkProgram(program);

  // Free the shader objects
  glDetachShader(program, vertShader);
  glDeleteShader(vertShader);
  glDetachShader(program, fragShader);
  glDeleteShader(fragShader);

  return program;
}

unsigned int makeTexture(unsigned int w, unsigned int h, unsigned int format,
                         char *data)
{
  unsigned int texture;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  if (data == 0)
  {
    glTexImage2D(GL_TEXTURE_2D, 0, format, w, h, 0, format, GL_FLOAT, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    // TODO Are those three really necessary?
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
  }
  else
  {
    glTexImage2D(GL_TEXTURE_2D, 0, format, w, h, 0, format, GL_UNSIGNED_BYTE,
                 data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                    GL_LINEAR_MIPMAP_LINEAR);
  }
  return texture;
}

unsigned int makeFramebuffer(int w, int h, int n)
{
  unsigned int framebuffer, textures[n], types[n];
  glGenFramebuffers(1, &framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

  for (int i = 0; i < n; i++)
  {
    textures[i] = makeTexture(h, w, i < n - 1 ? GL_RGBA : GL_DEPTH_COMPONENT, 0);
    types[i] = i < n - 1 ? GL_COLOR_ATTACHMENT0 + i : GL_DEPTH_ATTACHMENT;
    glFramebufferTexture2D(GL_FRAMEBUFFER, types[i], GL_TEXTURE_2D, textures[i],
                           0);
  }
  glDrawBuffers(n, types);
  return framebuffer;
}

unsigned int makeBuffer(GLenum target, unsigned int size, void *data)
{
  unsigned int buffer;
  glGenBuffers(1, &buffer);
  glBindBuffer(target, buffer);
  glBufferData(target, (long)size, data, GL_STATIC_DRAW);
  return buffer;
}
