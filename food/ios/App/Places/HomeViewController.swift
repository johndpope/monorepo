import UIKit
import CoreLocation
import SVProgressHUD

extension HomeViewController : FilterModuleDelegate {
  func filterUpdated(_ viewController: UIViewController, filter: FilterModule) {
    viewController.dismiss(animated: true, completion: nil)

    self.placeStore.filterModule = filter

    if let labelText = filter.labelText() {
      self.filterBar.attributedText = labelText
      self.filterBarIsHidden = false
    } else {
      self.filterBar.attributedText = nil
      self.filterBarIsHidden = true
    }

    let filtered = filter.authorsFiltered() || filter.pricesFiltered() || filter.nabesFiltered() || filter.ratingsFiltered()
    self.filterButton.isSelected = filtered
    self.cuisineButton.isSelected = filter.cuisinesFiltered()
    self.sortButton.isSelected = filter.sortMode != .distance

    let active = filter.active()
    self.mapViewController.showIndex = active
    self.listViewController.showIndex = active

    self.mapViewController.controllerIdentifierKey = active ? "filtered-results" : "home"
    self.listViewController.controllerIdentifierKey = active ? "filtered-results" : "home"

    let coordinate = locationManager.latestLocation?.coordinate ?? locationManager.defaultCoordinate
    self.refresh(coordinate: coordinate) { (places) -> (Void) in
      if places.count == 0 {
        self.analytics.log(.noResultsWhenFiltering(filterModule: filter))
      }
    }
  }

}

extension HomeViewController : UISearchBarDelegate {

  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = true
  }

  func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.showsCancelButton = false
    return true
  }

  func searchBarTextDidChange(searchText: String) {
    self.placeStore.updateFilter(searchText: searchText)
  }

  func clearSearch() {
    if searchBar.text != "" {
      searchBar.text = ""
      searchBarTextDidChange(searchText: "")
    }
    searchBar.resignFirstResponder()
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText == "" {
      searchBarTextDidChange(searchText: "")
    }
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    self.analytics.log(.searchForRestaurant(searchTerm: searchBar.text ?? ""))
    clearSearch()
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    self.analytics.log(.searchForRestaurant(searchTerm: searchBar.text ?? ""))
    searchBarTextDidChange(searchText: searchBar.text ?? "")
    searchBar.resignFirstResponder()
  }

}

class HomeViewController: PlacesViewController {

  lazy var filterButton: UIButton! = {
    let filterButton = UIButton(frame: .zero)
    filterButton.setImage(UIImage(named: "filter-button"), for: .normal)
    filterButton.setImage(UIImage(named: "filter-button-selected"), for: .selected)
    filterButton.setImage(UIImage(named: "filter-button-selected"), for: .highlighted)
    filterButton.addTarget(self, action: #selector(showFilter), for: .touchUpInside)
    return filterButton
  }()

  lazy var sortButton : UIButton! = {
    let sortButton = UIButton(frame: .zero)
    sortButton.setImage(UIImage(named: "sort-button"), for: .normal)
    sortButton.setImage(UIImage(named: "sort-button-selected"), for: .selected)
    sortButton.setImage(UIImage(named: "sort-button-selected"), for: .highlighted)
    sortButton.addTarget(self, action: #selector(showSort), for: .touchUpInside)
    return sortButton
  }()

  lazy var cuisineButton : UIButton! = {
    let cuisineButton = UIButton(frame: .zero)
    cuisineButton.setImage(UIImage(named: "cuisine-button"), for: .normal)
    cuisineButton.setImage(UIImage(named: "cuisine-button-selected"), for: .selected)
    cuisineButton.setImage(UIImage(named: "cuisine-button-selected"), for: .highlighted)
    cuisineButton.addTarget(self, action: #selector(showCategories), for: .touchUpInside)
    return cuisineButton
  }()

  lazy var searchBar: UISearchBar! = {
    let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 600, height: 60))
    searchBar.setSearchFieldBackgroundImage(UIImage(named: "search-bar"), for: .normal)

    let placeholderAppearance = UILabel.appearance(whenContainedInInstancesOf: [UISearchBar.self])
    placeholderAppearance.font = UIFont.lightSmall

    let searchTextAppearance = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
    searchTextAppearance.font = UIFont.lightSmall

    searchBar.searchTextPositionAdjustment = UIOffset(horizontal: -10, vertical: 0)
    searchBar.setImage(UIImage(), for: UISearchBar.Icon.search, state: .normal)
    searchBar.placeholder = "Type a restaurant name"
    searchBar.delegate = self
    searchBar.tintColor = .oceanBlue
    return searchBar
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.backBarButtonItem  = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

    self.mapViewController.controllerIdentifierKey = "home"
    self.listViewController.controllerIdentifierKey = "home"
    self.navigationItem.titleView =  self.searchBar

    let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let one = UIBarButtonItem(customView: self.filterButton)
    let two = UIBarButtonItem(customView: self.sortButton)
    let three = UIBarButtonItem(customView: self.cuisineButton)

    self.topBar.setItems([space, space, space, one, space, two, space, three, space, space, space], animated: false)

    self.emptyView.isHidden = true
    self.view.insertSubview(self.emptyView, belowSubview: self.topBar)

    // Cache is empty on first load and after Realm schema changes
    // In latter case, indicate fetching underway w/ spinner.
    cache.isEmpty$
      .bind(onNext: { [weak self] isEmpty in
        if isEmpty {
          self?.spinner(.show)
        } else {
          self?.spinner(.hide)
        }
      })
      .disposed(by: rx.disposeBag)

  }

  lazy var emptyView : EmptyView = {
    let view = EmptyView()
    view.emptyImageView.image = UIImage(named: "no-results")
    view.emptyTitleLabel.text = "Try another search!"
    view.emptySubtitleLabel.text = "We couldn’t find any results,\nbut try searching for something more general."
    view.backgroundColor = .white
    return view
  }()

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    self.emptyView.frame = self.view.bounds
  }

  func dismissSearch(sender: UIButton) {
    self.searchBar.resignFirstResponder()
  }

  @objc func showCategories() {
    clearSearch()
    self.analytics.log(.tapsCuisineButton)
    let cuisineFilter = CuisinesViewController(context: self.context, filter: self.placeStore.filterModule)
    cuisineFilter.delegate = self
    let navigationController = PopupViewController(rootViewController: cuisineFilter)
    let screenHeight = AppDelegate.shared().window?.frame.size.height ?? 568
    navigationController.popUpHeight = max(screenHeight - 130 - 122, 568 - 20 - 40)
    navigationController.modalPresentationStyle = .overFullScreen
    navigationController.modalTransitionStyle = .crossDissolve
    self.navigationController?.present(navigationController, animated: true, completion: nil)
  }

  @objc func showFilter() {
    clearSearch()
    self.analytics.log(.tapsFilterButton)
    let filter = FilterViewController(context: self.context, filter: self.placeStore.filterModule)
    filter.filterDelegate = self
    let navigationController = PopupViewController(rootViewController: filter)
    let screenHeight = AppDelegate.shared().window?.frame.size.height ?? 568
    navigationController.popUpHeight = max(screenHeight - 81 - 74, 568 - 20 - 40)
    navigationController.modalPresentationStyle = .overFullScreen
    navigationController.modalTransitionStyle = .crossDissolve
    self.navigationController?.present(navigationController, animated: true, completion: nil)
  }


  @objc func showSort() {
    clearSearch()
    self.analytics.log(.tapsSortButton)
    let sort = SortViewController(analytics: self.analytics, filter: self.placeStore.filterModule)
    sort.sortDelegate = self
    let navigationController = PopupViewController(rootViewController: sort)
    navigationController.popUpHeight = 238
    navigationController.modalPresentationStyle = .overFullScreen
    navigationController.modalTransitionStyle = .crossDissolve
    self.navigationController?.present(navigationController, animated: true, completion: nil)
  }


  // PlaceStoreDelegate

  override func filterText() -> String? {
    return self.searchBar.text
  }

  override func didSetPlaceFiltered() {
    if self.placeStore.places.isEmpty {
      let searchTerm = self.searchBar.text ?? ""
      if searchTerm.isNotEmpty {
        self.analytics.log(.noResultsWhenSearching(searchTerm: searchTerm))
      }
    }
  }

  override func fetchedData(_ changeset: PlacesChangeset, _ setData: PlacesChangesetClosure) {
    super.fetchedData(changeset, setData)
    self.emptyView.isHidden = !isEmpty()
  }

}
