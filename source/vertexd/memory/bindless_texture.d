deprecated module vertexd.memory.bindless_texture;

// import bindbc.opengl;
// import gamut;
// import std.conv : to;
// import std.exception : enforce;
// import std.math;
// import std.stdio;
// import vdmath.mat;
// import vertexd.util.misc : bitWidth;
// import vertexd.shaders;

// class BindlessTexture { // TextureHandle
//     Texture base;
//     Sampler sampler;
//     GLuint64 handleID = 0; // no handle
//     private bool loaded = false;

//     string name;

//     int texCoord;
//     float factor = 1;

//     static ubyte[] bufferBytes(BindlessTexture texture) {
//         ubyte[] bytes = new ubyte[16]; // 16 '0 bytes'
//         if (texture is null)
//             return bytes;

//         bytes[0 .. 8] = (cast(ubyte*)&texture.handleID)[0 .. GLuint64.sizeof];
//         bytes[8 .. 12] = (cast(ubyte*)&texture.texCoord)[0 .. int.sizeof];
//         bytes[12 .. 16] = (cast(ubyte*)&texture.factor)[0 .. float.sizeof];
//         return bytes;
//     }

//     @disable this();

//     this(Texture base, Sampler sampler, string name = "BindlessTexture") {
//         this.base = base;
//         this.sampler = sampler;
//         this.name = name;
//     }

//     ~this() {
//         unload();
//         write("TextureHandle removed (remains till base & sampler are removed): ");
//         writeln(handleID);
//     }

//     void initialize(bool srgb, bool mipmap) {
//         if (this.handleID != 0) {
//             writeln("TextureHandle cannot be re-initialized!");
//             return;
//         }

//         if (!base.initialized) {
//             base.initialize(srgb, mipmap);
//             base.upload();
//         }

//         this.handleID = glGetTextureSamplerHandleARB(base.id, sampler.id);
//         enforce(handleID != 0, "An error occurred while creating a texture handle");

//         writeln("TextureHandle created: " ~ handleID.to!string);
//     }

//     void load() {
//         if (!loaded)
//             glMakeTextureHandleResidentARB(handleID);
//         this.loaded = true;
//     }

//     void unload() {
//         if (loaded)
//             glMakeTextureHandleNonResidentARB(handleID);
//         this.loaded = false;
//     }
// }
