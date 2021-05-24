//
//  Constants.swift
//  PoC UIKit
//
//  Created by Seunghun Yang on 2021/05/17.
//

import UIKit
import Nuke
import Vision

let backgroundColor = UIColor(red: 252 / 255, green: 247 / 255, blue: 227 / 255, alpha: 1.0)
let buttonColor = UIColor(red: 250 / 255, green: 136 / 255, blue: 136 / 255, alpha: 1.0)

let cornerRadius = CGFloat(20)

let nukeOptions = ImageLoadingOptions(
    transition: .fadeIn(duration: 0.45)
)

let jointNames: [VNHumanBodyPoseObservation.JointName] = [.leftAnkle,
                                                          .leftKnee,
                                                          .leftHip,
                                                          .leftShoulder,
                                                          .leftElbow,
                                                          .leftWrist,
                                                          .leftEye,
                                                          .leftEar,
                                                          .rightAnkle,
                                                          .rightKnee,
                                                          .rightHip,
                                                          .rightShoulder,
                                                          .rightElbow,
                                                          .rightWrist,
                                                          .rightEye,
                                                          .rightEar,
                                                          .nose]
