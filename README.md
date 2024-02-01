## VertexD is a hobby glTF Renderer/Engine, created to learn DLang & OpenGL

### Requirements:
- Dlang compiler [(eg dmd)](https://dlang.org/).
- Package manager [dub](https://dub.pm/getting_started) (included with dmd compiler).
- [GLFW library files](https://www.glfw.org/); `glfw3dll.lib` to build, `glfw3.dll` to run.


Dmd can also be installed using [chocolatey](https://chocolatey.org/) using `choco install dmd`.

### Sample
A sample/testing project can be viewed at accessory repo [VertexD_sample](https://github.com/HuskyNator/VertexD_sample)

![](sample.gif)

## Use Guide
### Initialization
In order to use most functionality (save for `misc`, `json`, `quaternion` and `mat` functionality), the library needs to be initialized using `vdInit`, initializing GLFW.

An OpenGL context also needs to be initialized by created a `new Window`.
### Rendering
At minimum, the window needs to be assigned a `World` class, generally imported by the `gltf_reader` importer. A `Camera` is also required (though it can be included in the respective gltf file).

A single render step can be taken using `vdStep`, although `vdLoop` is generally preferred.

### Input
Input should preferrably be handled by manually adding callbacks (`KeyInput`/`MousebuttonInput`/`MousepositionInput`/`MousewheelInput`) to the window.

## Versions
_(dub version modifiers to further control behaviour)_
- MultiThreadImageLoad - use multithreading to decode used gltf images.
