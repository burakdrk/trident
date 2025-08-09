//
//  ChatViewController.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-06.
//

import SDWebImage
import SwiftUI
import UIKit

// MARK: - View Controller

final class ChatViewController: UIViewController {
    private let viewModel = ChatViewModel()
    private let tableView = UITableView()

    private var scrollButtonVC: UIHostingController<ScrollButtonView>!
    private let scrollButtonVM = ScrollButtonViewModel()

    private var inScrollAnimation = false
    private var lastY: CGFloat = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureScrollButtonView()

        SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)

        viewModel.onBatchFlush = { [weak self] batch in
            self?.flushBuffer(batch)
        }
        viewModel.setNewMessageCount = { [weak self] count in
            self?.scrollButtonVM.newMessageCount = count
        }

        // Start async fetch tasks
        Task { try? await viewModel.beginConsumingMessageStream() }
    }

    private func configureTableView() {
        view.addAndFillSubview(tableView)
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.contentInsetAdjustmentBehavior = .never
    }

    @MainActor
    private func flushBuffer(_ newItems: [RenderableMessage]) {
        guard !newItems.isEmpty else { return }

        // Update backing array
        let insertCount = newItems.count
        let currentCount = viewModel.messages.count
        viewModel.messages.prepend(contentsOf: newItems)

        // Compute deletes if overflow
        var deleteIndexPaths: [IndexPath] = []
        if viewModel.messages.count > viewModel.maxMessages {
            let overflow = viewModel.messages.count - viewModel.maxMessages
            let start = currentCount - overflow
            let end = currentCount
            deleteIndexPaths = (start..<end).map { .init(row: $0, section: 0) }
            viewModel.messages.removeLast(overflow)
        }

        // Compute insert index‐paths
        let insertIndexPaths = (0..<insertCount).map { IndexPath(row: $0, section: 0) }

        // One batch update for everything
        UIView.performWithoutAnimation {
            tableView.performBatchUpdates({
                tableView.insertRows(at: insertIndexPaths, with: .none)
                if !deleteIndexPaths.isEmpty {
                    tableView.deleteRows(at: deleteIndexPaths, with: .none)
                }
            }, completion: { _ in
                if !self.inScrollAnimation {
                    self.scrollToBottom()
                }
            })
        }
    }

    private func scrollToBottom(animated: Bool = false) {
        if tableView.numberOfRows(inSection: 0) > 0, !viewModel.isPaused {
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}

// MARK: - Data Source

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.reuseID, for: indexPath) as! MessageCell
        cell.makeMessage(message: viewModel.messages[indexPath.row], font: UIFont.systemFont(ofSize: 16))

        return cell
    }
}

// MARK: - Delegate

extension ChatViewController: UITableViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastY = scrollView.contentOffset.y

        if !viewModel.isPaused {
            viewModel.isPaused = true
            scrollButtonVM.setShown(true, animated: false)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        inScrollAnimation = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 20

        let bottomY = -scrollView.adjustedContentInset.top
        let y = scrollView.contentOffset.y
        let dy = y - lastY // moving toward bottom
        lastY = y

        let isUserScroll = scrollView.isDragging || scrollView.isDecelerating
        let nearBottom = y <= bottomY + threshold

        if isUserScroll, nearBottom, dy < 0 {
            viewModel.isPaused = false
            scrollButtonVM.setShown(false)
        }
    }
}

// MARK: - Scroll Button View

extension ChatViewController {
    private func configureScrollButtonView() {
        let scrollButtonView = ScrollButtonView(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self.viewModel.isPaused = false
            self.scrollButtonVM.setShown(false)
            self.scrollToBottom(animated: true)
            self.inScrollAnimation = true
        }, vm: scrollButtonVM)
        scrollButtonVC = UIHostingController(rootView: scrollButtonView)
        addChild(scrollButtonVC)

        scrollButtonVC.view.backgroundColor = .clear

        scrollButtonVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollButtonVC.view)

        NSLayoutConstraint.activate([
            scrollButtonVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollButtonVC.view.widthAnchor.constraint(equalTo: view.widthAnchor),

            scrollButtonVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])

        scrollButtonVC.didMove(toParent: self)
    }
}

// MARK: - SwiftUI Wrapper

struct ChatView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ChatViewController { .init() }
    func updateUIViewController(_ uiViewController: ChatViewController, context: Context) {}
}

#Preview {
    ChatView()
        .edgesIgnoringSafeArea(.all)
}
