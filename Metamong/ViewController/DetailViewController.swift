//
//  DetailViewController.swift
//  PoC UIKit
//
//  Created by Seunghun Yang on 2021/05/17.
//

import UIKit
import SnapKit
import Nuke
import JGProgressHUD

class DetailViewController: UIViewController {
    
    // MARK: - Properties
    var viewModel: DetailViewModel?
    
    var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .systemGray3
        return imageView
    }()
    
    var timeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = labelBackgroundColor.getUIColor
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = labelBackgroundColor.getUIColor
        label.font = UIFont.systemFont(ofSize: 40, weight: .heavy)
        label.textColor = .white
        return label
    }()
    
    var difficultyLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = labelBackgroundColor.getUIColor
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    var creatorLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = labelBackgroundColor.getUIColor
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.isUserInteractionEnabled = false
        textView.textAlignment = .left
        textView.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        textView.backgroundColor = .clear
        return textView
    }()
    
    lazy var startButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = cornerRadius
        button.layer.masksToBounds = true
        button.backgroundColor = buttonColor.getUIColor
        button.setTitle("시작하기", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        button.addTarget(self, action: #selector(self.handleStartButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(.init(systemName: "xmark.circle"), for: .normal)
        button.addTarget(self, action: #selector(self.handleCloseButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var downloadProgressHud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .dark)
        hud.vibrancyEnabled = true
        hud.indicatorView = JGProgressHUDPieIndicatorView()
        return hud
    }()
    
    lazy var downloadUrlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    var downloadTask: URLSessionDownloadTask? = nil
    
    // MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Helpers
    
    func configureUI() {
        self.view.backgroundColor = backgroundColor.getUIColor
        
        self.view.addSubview(self.thumbnailImageView)
        self.view.addSubview(self.timeLabel)
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.difficultyLabel)
        self.view.addSubview(self.creatorLabel)
        self.view.addSubview(self.descriptionTextView)
        self.view.addSubview(self.startButton)
        self.view.addSubview(self.closeButton)
        
        guard let viewModel = self.viewModel else { return }
        self.titleLabel.heroID = "title_\(viewModel.exercise.id)"
        self.creatorLabel.heroID = "creator_\(viewModel.exercise.id)"
        self.difficultyLabel.heroID = "difficulty_\(viewModel.exercise.id)"
        self.timeLabel.heroID = "time_\(viewModel.exercise.id)"
        self.thumbnailImageView.heroID = "thumbnail_\(viewModel.exercise.id)"
        
        self.view.bringSubviewToFront(self.titleLabel)
        self.view.bringSubviewToFront(self.difficultyLabel)
        self.view.bringSubviewToFront(self.closeButton)
        
        self.thumbnailImageView.snp.makeConstraints {
            $0.top.equalTo(self.view.snp.top)
            $0.left.equalTo(self.view.snp.left)
            $0.right.equalTo(self.view.snp.right)
            $0.height.equalTo(self.thumbnailImageView.snp.width).multipliedBy(1.1)
        }
        
        self.closeButton.snp.makeConstraints {
            $0.top.equalTo(self.view.snp.topMargin)
            $0.right.equalTo(self.view.snp.right).offset(-15)
        }
        
        self.titleLabel.snp.makeConstraints {
            $0.right.equalTo(self.view.snp.right).offset(-15)
            $0.bottom.equalTo(self.difficultyLabel.snp.top).offset(-8)
            $0.left.greaterThanOrEqualTo(self.view.snp.left).offset(15)
        }
        
        self.timeLabel.snp.makeConstraints {
            $0.left.equalTo(self.view.snp.left).offset(15)
            $0.top.equalTo(self.view.snp.topMargin)
        }
        
        self.difficultyLabel.snp.makeConstraints {
            $0.centerY.equalTo(self.creatorLabel.snp.centerY)
            $0.right.equalTo(self.view.snp.right).offset(-15)
        }
        
        self.creatorLabel.snp.makeConstraints {
            $0.bottom.equalTo(self.thumbnailImageView.snp.bottom).offset(-30)
            $0.left.equalTo(self.view.snp.left).offset(15)
            $0.right.lessThanOrEqualTo(self.difficultyLabel.snp.left).offset(-15)
        }
        
        self.descriptionTextView.snp.makeConstraints {
            $0.left.equalTo(self.view.snp.left).offset(15)
            $0.right.equalTo(self.view.snp.right).offset(-15)
            $0.top.equalTo(self.thumbnailImageView.snp.bottom).offset(15)
            $0.bottom.equalTo(self.startButton.snp.top).offset(-15)
        }
        
        self.startButton.snp.makeConstraints {
            $0.bottom.equalTo(self.view.snp.bottom).offset(-30)
            $0.left.equalTo(self.view.snp.left).offset(15)
            $0.right.equalTo(self.view.snp.right).offset(-15)
            $0.height.equalTo(50)
        }
        
        guard let viewModel = self.viewModel else { return }
        guard let thumbnailURL = URL(string: AWSS3Url + AWSS3BucketName + "/\(viewModel.exercise.id).jpeg") else { return }
        Nuke.loadImage(with: thumbnailURL, into: self.thumbnailImageView)
        self.titleLabel.text = viewModel.exercise.title
        self.timeLabel.text = viewModel.exercise.length.msToTimeString()
        self.creatorLabel.text = viewModel.exercise.creator
        self.difficultyLabel.text = viewModel.exercise.difficulty
        self.descriptionTextView.text = viewModel.exercise.description
        
        self.titleLabel.textColor = .white
        self.timeLabel.textColor = .white
        self.creatorLabel.textColor = .white
        self.difficultyLabel.textColor = .white
    }
    
    func showHud() {
        self.downloadProgressHud.indicatorView = JGProgressHUDPieIndicatorView()
        self.downloadProgressHud.show(in: self.view)
    }
    
    func dismissHud() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            UIView.animate(withDuration: 0.1, animations: {
                self.downloadProgressHud.textLabel.text = "다운로드 완료!"
                self.downloadProgressHud.detailTextLabel.text = nil
                self.downloadProgressHud.indicatorView = JGProgressHUDSuccessIndicatorView()
            })
            self.downloadProgressHud.dismiss(afterDelay: 1.0)
        }
    }
    
    func startDownload(url: URL) {
        let downloadTask = downloadUrlSession.downloadTask(with: url)
        downloadTask.resume()
        self.downloadTask = downloadTask
    }
    
    func downloadSequentially() {
        guard let viewModel = self.viewModel else { return }
        if viewModel.downloadingFileNamesStack.isEmpty {
            self.dismissHud()
            return
        }
        self.downloadProgressHud.textLabel.text = viewModel.downloadingMessagesStack.first
        self.showHud()
        self.startDownload(url: URL(string: AWSS3Url + AWSS3BucketName + "/" + viewModel.downloadingFileNamesStack.first!)!)
    }
    
    // MARK: - IBActions
    
    @objc func handleCloseButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleStartButtonTapped() {
        guard let viewModel = self.viewModel else { return }
        
        if viewModel.isAvailable {
            let exerciseReferenceViewController = ExerciseReferenceViewController()
            exerciseReferenceViewController.hero.isEnabled = true
            exerciseReferenceViewController.viewModel = ExerciseReferenceViewModel(id: viewModel.exercise.id)
            self.navigationController?.hero.navigationAnimationType = .fade
            self.navigationController?.pushViewController(exerciseReferenceViewController, animated: true)
        } else {
            self.downloadSequentially()
        }
    }
}

// MARK: - URLSessionDelegate

extension DetailViewController: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let viewModel = self.viewModel else { return }
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileUrl = documentDirectoryUrl.appendingPathComponent(viewModel.downloadingFileNamesStack.first!)
        viewModel.downloadingFileNamesStack.removeFirst()
        viewModel.downloadingMessagesStack.removeFirst()
        
        try? FileManager.default.moveItem(at: location, to: fileUrl)
        print("file moved from \(location) to \(fileUrl)")
        
        DispatchQueue.main.sync {
            if viewModel.downloadingFileNamesStack.isEmpty {
                self.dismissHud()
                return
            } else {
                self.downloadSequentially()
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if downloadTask == self.downloadTask {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            DispatchQueue.main.sync {
                self.downloadProgressHud.progress = calculatedProgress
                self.downloadProgressHud.detailTextLabel.text = String(format: "%.2f", (calculatedProgress * 100)) + "%"
            }
        }
    }
}
