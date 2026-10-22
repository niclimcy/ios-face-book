//
//  UserDetailViewController.swift
//  Face Book
//
//  Created by Nicholas Lim on 22/10/26.
//

import UIKit

class UserDetailViewController: UIViewController, UITableViewDataSource {
    private static let cellReuseIdentifier = "UserDetailCell"

    private struct DetailSection {
        let title: String
        let rows: [(label: String, value: String)]
    }

    private let user: SimplifiedUser
    private var sections: [DetailSection] = []

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "person.circle.fill")
        )
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 60
        imageView.tintColor = .secondaryLabel

        return imageView
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true

        return indicator
    }()

    init(user: SimplifiedUser) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupLayout()
        loadAvatar()
        fetchDetails()
    }

    private func setupUI() {
        title = user.fullName
        view.backgroundColor = .systemGroupedBackground

        tableView.dataSource = self
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: Self.cellReuseIdentifier
        )
        view.addSubview(tableView)

        let headerView = UIView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 160)
        )
        headerView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.centerXAnchor.constraint(
                equalTo: headerView.centerXAnchor
            ),
            avatarImageView.centerYAnchor.constraint(
                equalTo: headerView.centerYAnchor
            ),
            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            avatarImageView.heightAnchor.constraint(equalToConstant: 120),
        ])
        tableView.tableHeaderView = headerView

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

    private func loadAvatar() {
        guard let url = user.faceImageURL else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return }

                avatarImageView.image = image
            } catch {
                return
            }
        }
    }

    private func fetchDetails() {
        loadingIndicator.startAnimating()

        Task {
            defer { loadingIndicator.stopAnimating() }

            let url = URL(string: "https://dummyjson.com/users/\(user.id)")!

            do {
                let (data, response) = try await URLSession.shared.data(
                    from: url
                )

                if let httpResponse = response as? HTTPURLResponse {
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("❌ HTTP Error: \(httpResponse.statusCode)")
                        return
                    }
                }

                let detail = try JSONDecoder().decode(
                    UserDetail.self,
                    from: data
                )
                sections = makeSections(from: detail)
                tableView.reloadData()

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
    }

    private func makeSections(from detail: UserDetail) -> [DetailSection] {
        [
            DetailSection(
                title: "Personal",
                rows: [
                    ("Age", "\(detail.age)"),
                    ("Gender", detail.gender.capitalized),
                    ("Birth date", detail.birthDate),
                ]
            ),
            DetailSection(
                title: "Contact",
                rows: [
                    ("Email", detail.email),
                    ("Phone", detail.phone),
                ]
            ),
            DetailSection(
                title: "Work & Education",
                rows: [
                    ("Company", detail.company.name),
                    ("Job title", detail.company.title),
                    ("University", detail.university),
                ]
            ),
            DetailSection(
                title: "Address",
                rows: [
                    ("Street", detail.address.address),
                    ("City", detail.address.city),
                    ("State", detail.address.state),
                    ("Postal code", detail.address.postalCode),
                    ("Country", detail.address.country),
                ]
            ),
        ]
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        sections[section].rows.count
    }

    func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        sections[section].title
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellReuseIdentifier,
            for: indexPath
        )
        let row = sections[indexPath.section].rows[indexPath.row]

        var content = UIListContentConfiguration.valueCell()
        content.text = row.label
        content.secondaryText = row.value
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        cell.selectionStyle = .none

        return cell
    }
}
