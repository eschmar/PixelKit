//
//  MultiCameraPIX.swift
//  PixelKit
//
//  Created by Anton Heestand on 2019-12-02.
//

import Foundation
import CoreGraphics
import RenderKit
import Resolution

#if os(iOS) && !targetEnvironment(macCatalyst)
@available(iOS 13.0, macOS 10.15, *)
final public class MultiCameraPIX: PIXResource, PIXViewable {
    
    public typealias Model = MultiCameraPixelModel
    
    private var model: Model {
        get { resourceModel as! Model }
        set { resourceModel = newValue }
    }
    
    override public var shaderName: String { return "contentResourceCameraPIX" }
    
    // MARK: - Public Properties
    
    public var camera: CameraPIX.Camera {
        get { model.camera }
        set {
            model.camera = newValue
            guard let cameraPix = cameraPix else { return }
            guard cameraPix.setup == true else { return }
            cameraPix.setupCamera()
        }
    }
    
    public var cameraPix: CameraPIX? {
        willSet {
            if newValue == nil {
                if let cameraPix = cameraPix {
                    cameraPix.multi = false
                    cameraPix.multiCallbacks.removeAll(where: { $0.id == id })
                }
            }
        }
        didSet {
            guard let cameraPix = cameraPix else { return }
            guard cameraPix.multiCallbacks.filter({ $0.id == id }).isEmpty else { return }
            cameraPix.multiCallbacks.append(
                CameraPIX.MultiCallback(
                    id: id, camera: {  [weak self] in
                        self?.camera
                    },
                    setup: { [weak self] orientation in
                        self?.orientation = orientation
                        self?.flop = [.portrait, .portraitUpsideDown].contains(orientation)
                    },
                    frameLoop: { [weak self] pixelBuffer in
                        guard let self = self else { return }
                        PixelKit.main.logger.log(node: self, .info, .resource, "Multi Camera frame captured.", loop: true)
                        self.resourcePixelBuffer = pixelBuffer
                        if self.view.resolution == nil || self.view.resolution! != self.finalResolution {
                            self.applyResolution { self.render() }
                        } else {
                            self.render()
                        }
                })
            )
            cameraPix.multi = true
        }
    }
    
    var orientation: _Orientation?
    
    // MARK: - Property Helpers
    
    public override var uniforms: [CGFloat] {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        return [CGFloat(orientation?.rawValue ?? 0), camera.mirrored ? 1 : 0, camera.flipFlop ? 1 : 0]
        #elseif os(macOS) || targetEnvironment(macCatalyst)
        return [4, camera.mirrored ? 1 : 0, camera.flipFlop ? 1 : 0]
        #endif
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
    
    // MARK: - Live Model
    
    override func modelUpdateLive() {
        super.modelUpdateLive()
        super.modelUpdateLiveDone()
    }
    
    override func liveUpdateModel() {
        super.liveUpdateModel()
        super.liveUpdateModelDone()
    }
    
    // MARK: - Setup
    
    func setup() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.cameraPix == nil {
                PixelKit.main.logger.log(node: self, .warning, .resource, "Please set the .cameraPix property.")
                PixelKit.main.logger.log(node: self, .warning, .resource, "Also enable .multi on the CameraPIX.")
            }
        }
    }
    
    public static func setup(cameraPix: CameraPIX, camera: CameraPIX.Camera) -> MultiCameraPIX {
        
        cameraPix.multi = true
        
        let multiCameraPix = MultiCameraPIX()
        multiCameraPix.name = "multiCamera"
        multiCameraPix.camera = camera
        multiCameraPix.cameraPix = cameraPix
        
        return multiCameraPix
    }
}
#endif
