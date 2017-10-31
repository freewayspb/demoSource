
@PerActivity
public class TripDetailsPresenter extends BaseProgressPresenter<TripDetailsView> {

    private TripInteractor tripInteractor;
    private TripDetailsDataMapper tripDetailsDataMapper;
    private String orderId;

    @Inject
    public TripDetailsPresenter(TripInteractor tripInteractor, TripDetailsDataMapper tripDetailsDataMapper) {
        this.tripInteractor = tripInteractor;
        this.tripDetailsDataMapper = tripDetailsDataMapper;
    }

    @Override
    public void attachView(TripDetailsView view) {
        super.attachView(view);
        loadData(view);
    }

    private void loadData(TripDetailsView view) {
        view.onShowProgressDialog();
        addSubscription(tripInteractor.getOrderDetails(orderId)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .filter(data -> data != null && data.getOrderDetails() != null)
                .doOnNext(this::loadOrderDetails)
                .map(tripDetailsDataMapper)
                .doOnNext(this::showLoadedInfo)
                .observeOn(Schedulers.io())
                .map(TripDetailsLayoutData::getTrackUrl)
                .filter(trackUrl -> !TextUtils.isEmpty(trackUrl))
                .flatMap(tripInteractor::getTripTrackImage)
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(this::showTrackImage, this::handleRxError));
    }

    public void openTripCosts(boolean openCostDetails) {
        TripDetailsView view = getView();
        if (view != null) {
            if (openCostDetails) {
                view.openTripCostDetails();
            } else {
                view.closeTripCostDetails();
            }
        }
    }

    public void openReports() {
        TripDetailsView view = getView();
        if (view != null) {
            view.openReports(orderId);
        }
    }

    private void loadOrderDetails(OrderDetailsResponseData orderDetailsResponseData) {
        TripDetailsView view = getView();
        if (view != null) {
            view.onLoadOrderDetails(orderDetailsResponseData.getOrderDetails());
        }
    }

    private void showTrackImage(Bitmap bitmap) {
        TripDetailsView view = getView();
        if (view != null) {
            view.showTripTrack(bitmap);
            view.hideTrackProgress();
        }
    }

    private void showLoadedInfo(TripDetailsLayoutData tripDetailsLayoutData) {
        TripDetailsView view = getView();
        if (view != null) {
            view.showTripData(tripDetailsLayoutData);
            view.onDismissProgressDialog();
        }
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }
}