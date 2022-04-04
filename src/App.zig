//! App is the primary GUI application for ghostty. This builds the window,
//! sets up the renderer, etc. The primary run loop is started by calling
//! the "run" function.
const App = @This();

const std = @import("std");
const gl = @import("opengl.zig");
const glfw = @import("glfw");

const log = std.log;

window: glfw.Window,

glprog: gl.Program,
vao: gl.VertexArray,

/// Initialize the main app instance. This creates the main window, sets
/// up the renderer state, compiles the shaders, etc. This is the primary
/// "startup" logic.
pub fn init() !App {
    // Create our window
    const window = try glfw.Window.create(640, 480, "ghostty", null, null, .{
        .context_version_major = 3,
        .context_version_minor = 3,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
    });
    errdefer window.destroy();

    // Setup OpenGL
    // NOTE(mitchellh): we probably want to extract this to a dedicated
    // renderer at some point.
    try glfw.makeContextCurrent(window);
    try glfw.swapInterval(1);
    window.setSizeCallback((struct {
        fn callback(_: glfw.Window, width: i32, height: i32) void {
            log.info("set viewport {} {}", .{ width, height });
            try gl.viewport(0, 0, width, height);
        }
    }).callback);

    // Compile our shaders
    const vs = try gl.Shader.create(gl.c.GL_VERTEX_SHADER);
    try vs.setSourceAndCompile(vs_source);
    errdefer vs.destroy();

    const fs = try gl.Shader.create(gl.c.GL_FRAGMENT_SHADER);
    try fs.setSourceAndCompile(fs_source);
    errdefer fs.destroy();

    // Link our shader program
    const program = try gl.Program.create();
    errdefer program.destroy();
    try program.attachShader(vs);
    try program.attachShader(fs);
    try program.link();
    vs.destroy();
    fs.destroy();

    // Create our bufer or vertices
    const vertices = [_]f32{
        -0.5, -0.5, 0.0, // left
        0.5, -0.5, 0.0, // right
        0.0, 0.5, 0.0, // top
    };
    const vao = try gl.VertexArray.create();
    //defer vao.destroy();
    const vbo = try gl.Buffer.create();
    //defer vbo.destroy();
    try vao.bind();
    var binding = try vbo.bind(gl.c.GL_ARRAY_BUFFER);
    try binding.setData(&vertices, gl.c.GL_STATIC_DRAW);
    try binding.vertexAttribPointer(0, 3, gl.c.GL_FLOAT, false, 3 * @sizeOf(f32), null);
    try binding.enableVertexAttribArray(0);
    binding.unbind();
    try gl.VertexArray.unbind();

    return App{
        .window = window,
        .glprog = program,

        .vao = vao,
    };
}

pub fn deinit(self: *App) void {
    self.window.destroy();
    self.* = undefined;
}

pub fn run(self: App) !void {
    while (!self.window.shouldClose()) {
        // Setup basic OpenGL settings
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.c.GL_COLOR_BUFFER_BIT);

        try self.glprog.use();
        try self.vao.bind();
        try gl.drawArrays(gl.c.GL_TRIANGLES, 0, 3);

        try self.window.swapBuffers();
        try glfw.waitEvents();
    }
}

const vs_source = @embedFile("../shaders/shape.v.glsl");
const fs_source = @embedFile("../shaders/shape.f.glsl");
