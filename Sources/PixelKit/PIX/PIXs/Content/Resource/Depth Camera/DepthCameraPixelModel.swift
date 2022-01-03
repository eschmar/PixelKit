//
//  Created by Anton Heestand on 2022-01-02.
//

import Foundation
import CoreGraphics
import RenderKit
import Resolution
import PixelColor

public struct DepthCameraPixelModel: PixelResourceModel {
    
    // MARK: Global
    
    public var id: UUID = UUID()
    public var name: String = "Depth Camera"
    public var typeName: String = "pix-content-resource-depth-camera"
    public var bypass: Bool = false
    
    public var outputNodeReferences: [NodeReference] = []

    public var viewInterpolation: ViewInterpolation = .linear
    public var interpolation: PixelInterpolation = .linear
    public var extend: ExtendMode = .zero
}

extension DepthCameraPixelModel {
    
    public init(from decoder: Decoder) throws {
        self = try PixelResourceModelDecoder.decode(from: decoder, model: self) as! Self
    }
}
