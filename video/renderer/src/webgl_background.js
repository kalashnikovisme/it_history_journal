/* WebGL animated background — particle field */

class WebGLBackground {
  constructor() {
    this.canvas = null;
    this.gl = null;
    this.particles = [];
    this.animationId = null;
    this.startTime = 0;
    this.program = null;
  }

  init(canvas) {
    this.canvas = canvas;
    canvas.width = 1080;
    canvas.height = 1920;

    const gl = canvas.getContext('webgl', {
      alpha: true,
      antialias: true,
      preserveDrawingBuffer: true,
    });

    if (!gl) {
      console.warn('WebGL not available, skipping background');
      return false;
    }

    this.gl = gl;
    this._initShaders();
    this._initParticles(140);
    return true;
  }

  _initShaders() {
    const gl = this.gl;

    const vsSource = `
      attribute vec2 a_position;
      attribute float a_size;
      attribute float a_alpha;
      uniform vec2 u_resolution;
      varying float v_alpha;

      void main() {
        vec2 clip = (a_position / u_resolution) * 2.0 - 1.0;
        clip.y = -clip.y;
        gl_Position = vec4(clip, 0.0, 1.0);
        gl_PointSize = a_size;
        v_alpha = a_alpha;
      }
    `;

    const fsSource = `
      precision mediump float;
      varying float v_alpha;

      void main() {
        vec2 coord = gl_PointCoord - vec2(0.5);
        float dist = length(coord);
        if (dist > 0.5) discard;
        float edge = 1.0 - smoothstep(0.3, 0.5, dist);
        gl_FragColor = vec4(0.914, 0.871, 0.953, v_alpha * edge);
      }
    `;

    const vs = this._compileShader(gl.VERTEX_SHADER, vsSource);
    const fs = this._compileShader(gl.FRAGMENT_SHADER, fsSource);

    const program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      console.error('Shader link error:', gl.getProgramInfoLog(program));
      return;
    }

    this.program = program;
    this.attrs = {
      position: gl.getAttribLocation(program, 'a_position'),
      size: gl.getAttribLocation(program, 'a_size'),
      alpha: gl.getAttribLocation(program, 'a_alpha'),
      resolution: gl.getUniformLocation(program, 'u_resolution'),
    };

    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
  }

  _compileShader(type, source) {
    const gl = this.gl;
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.error('Shader compile error:', gl.getShaderInfoLog(shader));
      gl.deleteShader(shader);
      return null;
    }
    return shader;
  }

  _initParticles(count) {
    this.particles = [];
    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: Math.random() * 1080,
        y: Math.random() * 1920,
        vx: (Math.random() - 0.5) * 0.25,
        vy: -(Math.random() * 0.3 + 0.05), // float upward
        size: Math.random() * 3 + 1.5,
        baseAlpha: Math.random() * 0.15 + 0.08,
        phase: Math.random() * Math.PI * 2,
        speed: Math.random() * 0.4 + 0.6,
      });
    }
  }

  start() {
    if (!this.gl) return;
    this.startTime = performance.now();
    this._loop();
  }

  stop() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }
  }

  _loop() {
    this.animationId = requestAnimationFrame(() => this._loop());
    this._render();
  }

  _render() {
    const gl = this.gl;
    const t = (performance.now() - this.startTime) / 1000;

    // Update particles
    for (const p of this.particles) {
      p.x += p.vx * p.speed;
      p.y += p.vy * p.speed;

      // Wrap vertically
      if (p.y < -10) {
        p.y = 1930;
        p.x = Math.random() * 1080;
      }
      // Wrap horizontally
      if (p.x < -10) p.x = 1090;
      if (p.x > 1090) p.x = -10;
    }

    gl.viewport(0, 0, 1080, 1920);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);

    gl.useProgram(this.program);
    gl.uniform2f(this.attrs.resolution, 1080, 1920);

    const positions = new Float32Array(this.particles.length * 2);
    const sizes     = new Float32Array(this.particles.length);
    const alphas    = new Float32Array(this.particles.length);

    for (let i = 0; i < this.particles.length; i++) {
      const p = this.particles[i];
      positions[i * 2]     = p.x;
      positions[i * 2 + 1] = p.y;
      sizes[i]  = p.size;
      // Gentle pulse
      alphas[i] = p.baseAlpha * (0.7 + 0.3 * Math.sin(t * 1.2 + p.phase));
    }

    const posBuf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, posBuf);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.DYNAMIC_DRAW);
    gl.enableVertexAttribArray(this.attrs.position);
    gl.vertexAttribPointer(this.attrs.position, 2, gl.FLOAT, false, 0, 0);

    const sizeBuf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, sizeBuf);
    gl.bufferData(gl.ARRAY_BUFFER, sizes, gl.DYNAMIC_DRAW);
    gl.enableVertexAttribArray(this.attrs.size);
    gl.vertexAttribPointer(this.attrs.size, 1, gl.FLOAT, false, 0, 0);

    const alphaBuf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, alphaBuf);
    gl.bufferData(gl.ARRAY_BUFFER, alphas, gl.DYNAMIC_DRAW);
    gl.enableVertexAttribArray(this.attrs.alpha);
    gl.vertexAttribPointer(this.attrs.alpha, 1, gl.FLOAT, false, 0, 0);

    gl.drawArrays(gl.POINTS, 0, this.particles.length);

    // Cleanup buffers
    gl.deleteBuffer(posBuf);
    gl.deleteBuffer(sizeBuf);
    gl.deleteBuffer(alphaBuf);
  }
}

window.WebGLBackground = WebGLBackground;
