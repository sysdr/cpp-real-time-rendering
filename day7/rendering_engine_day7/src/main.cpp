#include <iostream>
#include <iomanip>
#include <cstdio>
#include <vector>
#include <cmath>

// Include GLEW and GLFW
#define GLEW_STATIC
#include <GL/glew.h>
#include <GLFW/glfw3.h>

// --- Console output helpers ---
static void printBanner() {
    std::cout << "\n";
    std::cout << "  ============================================================\n";
    std::cout << "    Day 7: Vertex Buffer Object (VBO) - Real-Time Rendering\n";
    std::cout << "  ============================================================\n";
    std::cout << "  This demo shows how OpenGL draws geometry using:\n";
    std::cout << "    * Vertex Buffer Object (VBO) - GPU memory for vertices\n";
    std::cout << "    * Vertex + Fragment shaders - run on the GPU\n";
    std::cout << "    * One triangle (3 vertices) drawn every frame\n";
    std::cout << "  ------------------------------------------------------------\n";
    std::cout << std::flush;
}

static void printStep(const char* step, const char* detail) {
    std::cout << "  [OK] " << std::left << std::setw(28) << step << " " << detail << "\n" << std::flush;
}

// Simple Vertex Shader
const char* vertexShaderSource = R"glsl(
    #version 330 core
    layout (location = 0) in vec3 aPos;
    void main()
    {
        gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    }
)glsl";

// Simple Fragment Shader
const char* fragmentShaderSource = R"glsl(
    #version 330 core
    out vec4 FragColor;
    void main()
    {
        FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f); // Orange color
    }
)glsl";

// Global variables for shader program, VAO and VBO
GLuint shaderProgram;
GLuint VAO;
GLuint VBO;

void framebuffer_size_callback(GLFWwindow* window, int width, int height) {
    glViewport(0, 0, width, height);
}

void processInput(GLFWwindow *window) {
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
}

void setupShaders() {
    std::cout << "  --- Shaders ---\n";
    // Vertex Shader
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);
    int success;
    char infoLog[512];
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        std::cerr << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
    } else
        printStep("Vertex shader", "compiled (position -> gl_Position)");

    // Fragment Shader
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        std::cerr << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << infoLog << std::endl;
    } else
        printStep("Fragment shader", "compiled (orange color output)");

    // Shader Program
    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
        std::cerr << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
    } else
        printStep("Shader program", "linked and ready\n");

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
}

void setupVBO() {
    std::cout << "  --- VAO + VBO (Vertex Buffer Object) ---\n";
    // In OpenGL 3.3 Core we must use a VAO; it stores the vertex attribute layout.
    glGenVertexArrays(1, &VAO);
    glBindVertexArray(VAO);

    float vertices[] = {
        -0.5f, -0.5f, 0.0f, // Left
         0.5f, -0.5f, 0.0f, // Right
         0.0f,  0.5f, 0.0f  // Top
    };

    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // layout (location = 0) in vertex shader = position (vec3)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0); // unbind VAO (optional; we'll bind VAO each frame when drawing)

    printStep("VAO + VBO created", "3 vertices (triangle), 1 attribute (position)");
    std::cout << "  ---\n\n";
}

int main() {
    printBanner();

    // 1. Initialize GLFW
    if (!glfwInit()) {
        std::cerr << "Failed to initialize GLFW" << std::endl;
        return -1;
    }
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    printStep("GLFW", "initialized (OpenGL 3.3 Core)");

    // 2. Create a window
    const int winW = 800, winH = 600;
    GLFWwindow* window = glfwCreateWindow(winW, winH, "Day 7: Vertex Buffer Object", NULL, NULL);
    if (!window) {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    printStep("Window", "800x600, title: Day 7: Vertex Buffer Object");

    // 3. Initialize GLEW
    glewExperimental = GL_TRUE;
    if (glewInit() != GLEW_OK) {
        std::cerr << "Failed to initialize GLEW" << std::endl;
        return -1;
    }
    printStep("GLEW", "OpenGL loader ready");

    // 4. Setup Shaders and VBO
    setupShaders();
    setupVBO();

    std::cout << "  --- Render loop ---\n";
    printStep("Drawing", "1 triangle per frame (glDrawArrays)");
    std::cout << "  [INFO] Press ESC to close the window.\n";
    std::cout << "  ------------------------------------------------------------\n\n";

    // 5. Render loop with FPS in window title
    double lastTime = glfwGetTime();
    int frameCount = 0;
    double fpsUpdate = 0.0;

    while (!glfwWindowShouldClose(window)) {
        processInput(window);

        // Clear screen
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        // Use our shader program
        glUseProgram(shaderProgram);
        glBindVertexArray(VAO); // use our VAO (vertex attribute state is stored here)

        // Draw the triangle
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glBindVertexArray(0);

        glfwSwapBuffers(window);
        glfwPollEvents();

        // Update window title with FPS every 0.25 s
        frameCount++;
        double now = glfwGetTime();
        fpsUpdate += (now - lastTime);
        lastTime = now;
        if (fpsUpdate >= 0.25) {
            double fps = frameCount / fpsUpdate;
            frameCount = 0;
            fpsUpdate = 0.0;
            char title[128];
            snprintf(title, sizeof(title), "Day 7: VBO | Triangle | FPS: %.0f | ESC to quit", fps);
            glfwSetWindowTitle(window, title);
        }
    }

    // 6. Cleanup
    std::cout << "\n  [OK] Closing window and cleaning up (VAO, VBO, shaders, GLFW).\n\n";
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteProgram(shaderProgram);
    glfwTerminate();
    return 0;
}
