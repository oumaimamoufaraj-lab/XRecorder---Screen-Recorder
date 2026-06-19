//
//  BroadcastSetupViewController.swift
//  BroadcastUploadExtensionSetupUI
//

import ReplayKit
import UIKit

class BroadcastSetupViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(red: 0.973, green: 0.976, blue: 0.980, alpha: 1.0)

    let titleLabel = UILabel()
    titleLabel.text = "NowRecorder"
    titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
    titleLabel.textAlignment = .center
    titleLabel.textColor = UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1.0)

    let messageLabel = UILabel()
    messageLabel.text =
      "Tap Start Broadcast to begin full-screen recording with NowRecorder."
    messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 0
    messageLabel.textColor = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0)

    let startButton = UIButton(type: .system)
    startButton.setTitle("Start Broadcast", for: .normal)
    startButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    startButton.backgroundColor = UIColor(red: 1.0, green: 0.420, blue: 0.208, alpha: 1.0)
    startButton.setTitleColor(.white, for: .normal)
    startButton.layer.cornerRadius = 14
    startButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
    startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

    let cancelButton = UIButton(type: .system)
    cancelButton.setTitle("Cancel", for: .normal)
    cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
    cancelButton.setTitleColor(
      UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0),
      for: .normal
    )
    cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [
      titleLabel, messageLabel, startButton, cancelButton,
    ])
    stack.axis = .vertical
    stack.spacing = 16
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      startButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
    ])
  }

  @objc private func startTapped() {
    userDidFinishSetup()
  }

  @objc private func cancelTapped() {
    userDidCancelSetup()
  }

  private func userDidFinishSetup() {
    let broadcastURL = URL(string: "https://nowrecorder.local/broadcast")!
    let setupInfo: [String: NSCoding & NSObjectProtocol] = [
      "broadcastName": "NowRecorder" as NSString,
    ]
    extensionContext?.completeRequest(withBroadcast: broadcastURL, setupInfo: setupInfo)
  }

  private func userDidCancelSetup() {
    let error = NSError(
      domain: "com.xrecorder.screenVideo",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: "Broadcast setup cancelled."]
    )
    extensionContext?.cancelRequest(withError: error)
  }
}
