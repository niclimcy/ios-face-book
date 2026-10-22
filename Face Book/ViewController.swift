//
//  ViewController.swift
//  Face Book
//
//  Created by Nicholas Lim on 22/10/26.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource,
    UITableViewDelegate, UISearchBarDelegate
{
    private static let cellReuseIdentifier = "SimplifiedUserCell"
    private let userAPI = UserAPI()
    private var currentQuery: String?
    private var currentGender: UserAPI.Gender?
    private var canLoadMore = true
    private var isLoadingMore = false
    private var lastRequestedSkip: Int?

    var users: [SimplifiedUser] = []

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()

    private let searchBar = UISearchBar()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true

        return indicator
    }()

    private var searchTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupLayout()
        setupToolbar()
        if users.count == 0 {
            Task { await fetchUsers() }
        }
    }

    private func setupUI() {
        title = "Face Book"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UserCell.self,
            forCellReuseIdentifier: Self.cellReuseIdentifier
        )
        view.addSubview(tableView)

        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        footerView.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(
                equalTo: footerView.centerXAnchor
            ),
            loadingIndicator.centerYAnchor.constraint(
                equalTo: footerView.centerYAnchor
            ),
        ])
        tableView.tableFooterView = footerView
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            tableView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
            tableView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            tableView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
        ])
    }

    private func setupToolbar() {
        navigationController?.setToolbarHidden(false, animated: false)

        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.heightAnchor.constraint(equalToConstant: 36).isActive = true
        searchBar.sizeToFit()

        setupFilterGroup()
    }

    private func setupFilterGroup() {
        let allAction = UIAction(
            title: "All",
            state: currentGender == nil ? .on : .off
        ) { [weak self] _ in
            self?.applyGender(nil)
        }
        let genderActions = UserAPI.Gender.allCases.map { gender in
            UIAction(
                title: gender.title,
                state: currentGender == gender ? .on : .off
            ) { [weak self] _ in
                self?.applyGender(gender)
            }
        }

        let filterItem = UIBarButtonItem(
            image: UIImage(
                systemName: currentGender == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            ),
            menu: UIMenu(
                title: "Gender",
                children: [allAction] + genderActions
            )
        )
        filterItem.accessibilityLabel = "Filters"

        let searchItem = UIBarButtonItem(customView: searchBar)
        let flexibleSpace = UIBarButtonItem.flexibleSpace()

        toolbarItems = [searchItem, flexibleSpace, filterItem]
    }

    // MARK: - UITableViewDataSource

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        users.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: Self.cellReuseIdentifier,
                for: indexPath
            ) as! UserCell
        cell.configure(with: users[indexPath.row])

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        let detailViewController = UserDetailViewController(
            user: users[indexPath.row]
        )
        navigationController?.pushViewController(
            detailViewController,
            animated: true
        )
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            // The API can't combine search with filters, so searching clears the filter.
            if !query.isEmpty, currentGender != nil {
                currentGender = nil
                setupFilterGroup()
            }
            await fetchUsers(
                query: query.isEmpty ? nil : query,
                gender: query.isEmpty ? currentGender : nil
            )
        }
    }

    func fetchUsers(
        query: String? = nil,
        gender: UserAPI.Gender? = nil,
        skip: Int? = nil,
        append: Bool = false
    ) async {
        loadingIndicator.startAnimating()
        defer { loadingIndicator.stopAnimating() }

        do {
            let page = try await userAPI.fetchUsers(
                query: query,
                gender: gender,
                skip: skip
            )
            guard !Task.isCancelled else { return }

            currentQuery = query
            canLoadMore = (skip ?? 0) + page.users.count < page.total
            if !append {
                lastRequestedSkip = nil
            }
            if append {
                let start = users.count
                users += page.users
                tableView.insertRows(
                    at: (start..<users.count).map {
                        IndexPath(row: $0, section: 0)
                    },
                    with: .none
                )
            } else {
                users = page.users
                tableView.reloadData()
            }
        } catch is CancellationError {
            return

        } catch UserAPI.UserAPIError.httpStatus(let code) {
            print("❌ HTTP Error: \(code)")

        } catch DecodingError.keyNotFound(let key, let context) {
            print("❌ Missing key: '\(key.stringValue)'")
            print("Context: \(context.debugDescription)")

        } catch DecodingError.typeMismatch(let type, let context) {
            print("❌ Type mismatch for type: \(type)")
            print("Context: \(context.debugDescription)")

        } catch {
            print("❌ Error: \(error)")
        }
    }

    // Hint: Detect scroll position
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        guard contentHeight > height else { return }

        if offsetY > contentHeight - height {
            // Load more data
            loadMore()
        }
    }

    private func loadMore() {
        guard canLoadMore, !isLoadingMore else { return }

        isLoadingMore = true
        Task {
            defer { isLoadingMore = false }
            await fetchUsers(
                query: currentQuery,
                gender: currentGender,
                skip: users.count,
                append: true
            )
        }
    }

    private func applyGender(_ gender: UserAPI.Gender?) {
        searchTask?.cancel()
        searchBar.text = nil
        currentGender = gender
        setupFilterGroup()
        Task { await fetchUsers(gender: gender) }
    }
}

#Preview {
    UINavigationController(
        rootViewController: ViewController()
    )
}
