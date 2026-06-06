module vertexd.memory;

public {
    import vertexd.memory.bindless_texture;
    import vertexd.memory.buffer;
    import vertexd.memory.texture;
    import vertexd.memory.sampler;
    import vertexd.memory.vao;

    version (OpenGLBindless)
        alias DefaultTexture = BindlessTexture;
    else
        alias DefaultTexture = Texture;
}
