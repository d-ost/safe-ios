//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeUIKit
import MultisigWalletApplication
import Common

protocol AddTokenTableViewControllerDelegate: class {
    func didSelectToken(_ tokenData: TokenData)
}

class AddTokenTableViewController: UITableViewController {

    weak var delegate: AddTokenTableViewControllerDelegate!

    let searchController = UISearchController(searchResultsController: nil)
    let emptyView = EmptyResultsView()

    private let tokens = ApplicationServiceRegistry.walletService.hiddenTokens() // already sorted

    private var sectionedTokens = [String: [TokenData]]()
    private var filteredTokens = [TokenData]() {
        didSet {
            sectionedTokens = [:]
            filteredTokens.forEach {
                let sectionTitle = String($0.code.first!).uppercased()
                if sectionedTokens[sectionTitle] != nil {
                    sectionedTokens[sectionTitle]!.append($0)
                } else {
                    sectionedTokens[sectionTitle] = [$0]
                }
            }
            sectionTokensTitles = [String](sectionedTokens.keys).sorted()
            tableView.backgroundView = filteredTokens.isEmpty ?  emptyView : nil
            tableView.reloadData()
        }
    }
    private var sectionTokensTitles = [String]()

    private enum Strings {
        static let title = LocalizedString("add_token", comment: "Title for Add Token screen.")
        static let noResults = LocalizedString("no_results_found", comment: "No results found")
    }

    static func create(delegate: AddTokenTableViewControllerDelegate) -> UINavigationController {
        let navController = StoryboardScene.Main.addTokenNavigationController.instantiate()
        navController.navigationBar.isTranslucent = false
        let controller = navController.children[0] as! AddTokenTableViewController
        controller.delegate = delegate
        return navController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyView.text = Strings.noResults
        configureNavigationItem()
        configureSearchController()
        configureTableView()

        filteredTokens = tokens
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didShowKeyboard(_:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(MainTrackingEvent.addToken)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    private func configureNavigationItem() {
        title = Strings.title
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureSearchController() {
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.showsCancelButton = true
        searchController.searchBar.delegate = self
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.tintColor = ColorName.hold.color
    }

    private func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "BasicTableViewCell", bundle: Bundle(for: BasicTableViewCell.self)),
                           forCellReuseIdentifier: "BasicTableViewCell")
        tableView.register(BackgroundHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: "BackgroundHeaderFooterView")
        tableView.sectionFooterHeight = 0
        tableView.separatorStyle = .none

        tableView.rowHeight = BasicTableViewCell.titleAndSubtitleHeight
        tableView.backgroundColor = ColorName.white.color

        tableView.sectionIndexMinimumDisplayRowCount = 15
        tableView.sectionIndexColor = ColorName.darkGrey.color
    }

    @objc func didShowKeyboard(_ notification: NSNotification) {
        guard let screenValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardScreen = screenValue.cgRectValue
        emptyView.centerPadding = (EmptyResultsView.defaultCenterPadding + keyboardScreen.height) / 2
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTokensTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionedTokens[sectionTokensTitles[section]]!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicTableViewCell",
                                                 for: indexPath) as! BasicTableViewCell
        cell.configure(tokenData: token(for: indexPath),
                       displayBalance: false,
                       displayFullName: true,
                       accessoryType: .none)
        cell.withTrailingSpace = true
        return cell
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionTokensTitles
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate.didSelectToken(token(for: indexPath))
    }

    private func token(for indexPath: IndexPath) -> TokenData {
        return sectionedTokens[sectionTokensTitles[indexPath.section]]![indexPath.row]
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "BackgroundHeaderFooterView")
            as! BackgroundHeaderFooterView
        view.title = sectionTokensTitles[section]
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return BackgroundHeaderFooterView.height
    }

}

extension AddTokenTableViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text?.lowercased(), !text.isEmpty else {
            filteredTokens = tokens
            return
        }
        filteredTokens = tokens.filter {
            $0.code.lowercased().contains(text) || $0.name.lowercased().contains(text)
        }
    }

}

extension AddTokenTableViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: false)
    }

}
