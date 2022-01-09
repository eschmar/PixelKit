//
//  MetalMultiEffectPIX.swift
//  PixelKit
//
//  Created by Anton Heestand on 2018-09-07.
//  Open Source - MIT License
//

import CoreGraphics
import RenderKit
import Resolution
import Metal

/// Metal Shader (Multi Effect)
///
/// **Variables:** pi, u, v, uv, pixCount, texs, var.width, var.height, var.aspect, var.uniform
///
/// Example:
/// ```swift
/// let metalMultiEffectPix = MetalMultiEffectPIX(code:
///     """
///     float4 pixA = texs.sample(s, uv, 0);
///     float4 pixB = texs.sample(s, uv, 1);
///     float4 pixC = texs.sample(s, uv, 2);
///     return pixA + pixB + pixC;
///     """
/// )
/// metalMultiEffectPix.inputs = [ImagePIX("img_a"), ImagePIX("img_b"), ImagePIX("img_c")]
/// ```
final public class MetalMultiEffectPIX: PIXMultiEffect, NODEMetalCode, PIXViewable {
    
    public typealias Model = MetalMultiEffectPixelModel
    
    private var model: Model {
        get { multiEffectModel as! Model }
        set { multiEffectModel = newValue }
    }
    
    override public var shaderName: String { return "effectMultiMetalPIX" }
    
    // MARK: - Private Properties
    
    public let metalBaseCode: String =
    """
    #include <metal_stdlib>
    using namespace metal;

    /*<funcs>*/

    struct VertexOut{
        float4 position [[position]];
        float2 texCoord;
    };

    struct Uniforms{
        /*<uniforms>*/
        float width;
        float height;
        float aspect;
    };

    fragment float4 effectMultiMetalPIX(VertexOut out [[stage_in]],
                                          texture2d_array<float>  texs [[ texture(0) ]],
                                          const device Uniforms& var [[ buffer(0) ]],
                                          sampler s [[ sampler(0) ]]) {
        float pi = M_PI_F;
        float u = out.texCoord[0];
        float v = out.texCoord[1];
        float2 uv = float2(u, v);
        
        uint pixCount = texs.get_array_size();
        
        /*<code>*/
    }
    """
    
    public override var shaderNeedsResolution: Bool { return true }
    
    public var metalUniforms: [MetalUniform] {
        get { model.metalUniforms }
        set {
            model.metalUniforms = newValue
            listenToUniforms()
            bakeFrag()
        }
    }
    
    public var code: String{
        get { model.code }
        set {
            model.code = newValue
            bakeFrag()
        }
    }
    
    public var isRawCode: Bool = false
    
    public var metalCode: String? {
        if isRawCode { return code }
        metalConsole = nil
        do {
            return try PixelKit.main.render.embedMetalCode(uniforms: metalUniforms, code: code, metalBaseCode: metalBaseCode)
        } catch {
            PixelKit.main.logger.log(node: self, .error, .metal, "Metal code could not be generated.", e: error)
            return nil
        }
    }
    
    @Published public var metalConsole: String?
    public var metalConsolePublisher: Published<String?>.Publisher { $metalConsole }
    public var consoleCallback: ((String) -> ())?
    
    // MARK: - Property Helpers
    
    override public var values: [Floatable] {
        metalUniforms.map(\.value)
    }
    
    // MARK: - Life Cycle -
    
    public init(model: Model) {
        super.init(model: model)
        setup()
    }
    
    public required init() {
        let model = Model()
        super.init(model: model)
        setup()
    }
    
    public init(uniforms: [MetalUniform] = [], code: String) {
        let model = Model(metalUniforms: uniforms, code: code)
        super.init(model: model)
        setup()
    }
    
    #if swift(>=5.5)
    public convenience init(uniforms: [MetalUniform] = [], code: String,
                            @PIXBuilder inputs: () -> ([PIX & NODEOut])) {
        self.init(uniforms: uniforms, code: code)
        super.inputs = inputs()
    }
    #endif
    
    // MARK: - Setup
    
    private func setup() {
        bakeFrag()
        listenToUniforms()
    }
    
    // MARK: - Listen to Uniforms
    
    private func listenToUniforms() {
        for uniform in metalUniforms {
            uniform.didChangeValue = { [weak self] in
                self?.render()
            }
        }
    }
    
    // MARK: - Model
    
    override func modelUpdated() {
        super.modelUpdated()
        
        bakeFrag()
        listenToUniforms()
    }
    
    // MARK: - Live Model
    
    override func modelUpdateLive() {
        super.modelUpdateLive()
        super.modelUpdateLiveDone()
    }
    
    override func liveUpdateModel() {
        super.liveUpdateModel()
        super.liveUpdateModelDone()
    }
    
    // MARK: Bake Frag
    
    func bakeFrag() {
        metalConsole = nil
        do {
            let frag = try PixelKit.main.render.makeMetalFrag(shaderName, from: self)
            try makePipeline(with: frag)
        } catch {
            switch error {
            case Render.ShaderError.metalError(let codeError, let errorFrag):
                PixelKit.main.logger.log(node: self, .error, nil, "Metal code failed.", e: codeError)
                metalConsole = codeError.localizedDescription
                consoleCallback?(metalConsole!)
                do {
                    try makePipeline(with: errorFrag)
                } catch {
                    PixelKit.main.logger.log(node: self, .fatal, nil, "Metal fail failed.", e: error)
                }
            default:
                PixelKit.main.logger.log(node: self, .fatal, nil, "Metal bake failed.", e: error)
            }
        }
    }
    
    func makePipeline(with frag: MTLFunction) throws {
        pipeline = try PixelKit.main.render.makeShaderPipeline(frag, with: nil)
        render()
    }
    
}
