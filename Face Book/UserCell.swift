//
//  UserCell.swift
//  Face Book
//
//  Created by Nicholas Lim on 22/10/26.
//

import UIKit

class UserCell: UITableViewCell {
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.tintColor = .secondaryLabel

        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel

        return label
    }()

    private var imageTask: Task<Void, Never>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let textStack = UIStackView(arrangedSubviews: [
            nameLabel, locationLabel,
        ])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2

        contentView.addSubview(profileImageView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            profileImageView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            profileImageView.topAnchor.constraint(
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: 8
            ),
            profileImageView.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -8
            ),

            textStack.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor,
                constant: 12
            ),
            textStack.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            textStack.topAnchor.constraint(
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: 8
            ),
            textStack.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -8
            ),
            textStack.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageTask?.cancel()
        imageTask = nil
        profileImageView.image = placeholderImage
    }

    func configure(with user: SimplifiedUser) {
        nameLabel.text = user.fullName
        locationLabel.text = "\(user.city), \(user.state)"
        profileImageView.image = placeholderImage

        guard let url = user.faceImageURL else { return }

        imageTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data), !Task.isCancelled else {
                    return
                }

                self?.profileImageView.image = image
            } catch {
                return
            }
        }
    }

    private var placeholderImage: UIImage? {
        UIImage(systemName: "person.circle.fill")
    }
}
