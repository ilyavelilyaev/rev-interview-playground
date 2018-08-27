//
//  ViewController.swift
//  project
//
//  Created by Ilya Velilyaev on 27/08/2018.
//  Copyright © 2018 fwe2f232f213. All rights reserved.
//

import UIKit

struct Wallet {
    static var shared = Wallet()
    var money = [Money]()
    var rates = [Rate]()

    static func update(with data: Data) {
        let dict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        let rates = dict["rates"] as! [String: Double]
        let base = dict["base"] as! String
        shared.rates = rates.map { (arg) in Rate(fromCurrency: base, toCurrency: arg.key, value: arg.value) }
    }
}

typealias Currency = String
struct Money {
    let value: Double
    let currency: Currency
}

final class CryptoMoney: Money {
    let cryptoWallet: String
}

struct Rate {
    let fromCurrency: Currency
    let toCurrency: Currency
    let value: Double
}

protocol ExchangerDelegate: class {
    func exchanger(_ exchanger: Exchanger, didCalculateRate: Rate)
}

struct Exchanger {
    var delegate: ExchangerDelegate
    func exchange(money: Money, to: Currency) -> Money {
        let rate = Wallet.shared.rates.first { $0.fromCurrency == money.currency && $0.toCurrency == to }!.value
        return Money(value: money.value * rate, currency: to)
    }
}


final class ViewController : UIViewController {
    override func loadView() {
        self.view = ScrollableStackView(frame: .zero)
    }
}

final class ScrollableStackView: UIView {

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "swift"))
        imageView.transform = CGAffineTransform(rotationAngle: .pi / 4.0)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let button: UIButton = {
        let button = UIButton.init(type: .system)
        button.setTitle("Request rates", for: .normal)
        button.addTarget(self, action: #selector(buttonTouchedUpInside), for: .touchUpInside)
        return button
    }()

    private lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum, Lorem Ipsum is simply dummy text of the printing and typesetting industry."
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 15
        return stackView
    }()

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildViewHierarchy()
        setupConstaints()
        setupDefaults()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print(imageView.frame)
        print(imageView.bounds)
        print(imageView.image!.size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private func buildViewHierarchy() {
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)
        scrollView.addSubview(stackView)
        addSubview(scrollView)
    }

    private func setupConstaints() {

        let scollViewConstaints = [
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ]

        let guide = readableContentGuide
        let stackViewConstaints = [
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            ]

        NSLayoutConstraint.activate(scollViewConstaints)
        NSLayoutConstraint.activate(stackViewConstaints)
    }

    private func setupDefaults() {
        backgroundColor = .white
    }

    @objc private func buttonTouchedUpInside(_ sender: UIButton) {
        let url = URL(string: "https://revolut.duckdns.org/latest?base=EUR")!
        let dataTask = URLSession.shared.dataTask(with: url) { [unowned self] (data, response, error) in
            Wallet.update(with: data!)
            self.reload()
        }
    }

    private func reload() {
        self.label.text = Wallet.shared.money.reduce("", { prev, money in
            return prev + "\(money.currency) : \(money.value)\n"
        })
    }
}
