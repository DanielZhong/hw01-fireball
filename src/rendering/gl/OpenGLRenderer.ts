import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram, {Shader} from './ShaderProgram';

class OpenGLRenderer {
  backgroundShader: ShaderProgram;

  constructor(public canvas: HTMLCanvasElement) {
    // Initialize the background shader
    this.backgroundShader = new ShaderProgram([
      new Shader(gl.VERTEX_SHADER, require('../../shaders/flat-vert.glsl')),
      new Shader(gl.FRAGMENT_SHADER, require('../../shaders/flat-frag.glsl')),
    ]);
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, MyColor: vec4, MyScale: GLfloat, Persistency: GLfloat, Transparency: GLfloat) {
    // Render the background first using the backgroundShader
    let backgroundModel = mat4.create();
    let backgroundViewProj = mat4.create();
    mat4.identity(backgroundModel);
    mat4.multiply(backgroundViewProj, camera.projectionMatrix, camera.viewMatrix);
    this.backgroundShader.setModelMatrix(backgroundModel);
    this.backgroundShader.setViewProjMatrix(backgroundViewProj);
    for (let drawable of drawables) {
      this.backgroundShader.draw(drawable);
    }

    // Render the rest of the scene
    let model = mat4.create();
    let viewProj = mat4.create();
    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(MyColor);
    prog.setScale(MyScale);
    prog.setPersistency(Persistency);
    prog.setTransparency(Transparency);

    prog.draw(drawables[0]);
  }
};

export default OpenGLRenderer;
