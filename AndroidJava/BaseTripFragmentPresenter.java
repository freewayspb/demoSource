
public abstract class BaseTripFragmentPresenter<T extends BaseTripFragmentView> extends MvpBasePresenter<T> {

    private CompositeSubscription compositeSubscription;

    @Override
    public void attachView(T view) {
        super.attachView(view);
        compositeSubscription = new CompositeSubscription();
    }

    @Override
    public void detachView(boolean retainInstance) {
        super.detachView(retainInstance);
        compositeSubscription.unsubscribe();
    }

    public abstract void updateView();

    public void onBackPressed() {
        T view = getView();
        if (view != null) {
            view.onBackButtonClick();
        }
    }

    protected void addSubscription(final Subscription subscription) {
        compositeSubscription.add(subscription);
    }

    public void showProgressDialog() {
        T view = getView();
        if (view != null) {
            view.showProgressDialog();
        }
    }

    public void hideProgressDialog() {
        T view = getView();
        if (view != null) {
            view.hideProgressDialog();
        }
    }

    protected void onUnhandledTripLoadingError(Throwable error) {
        Timber.e(error);
        T view = getView();
        if (view != null) {
            view.hideProgressDialog();
            view.showErrorAlert(error.getMessage());
        }
    }

    protected void onTripLoadingError(String mes) {
        T view = getView();
        if (view != null) {
            view.hideProgressDialog();
            view.showErrorAlert(mes);
        }
    }

    protected void onHandledTripLoadingError(Throwable error) {
        Timber.e(error);
        if (error instanceof SocketErrorException) {
            SocketErrorException exception = (SocketErrorException) error;
            SocketError socketError = exception.getSocketError();
            this.onTripLoadingError(socketError.getErrorDesc());
        } else {
            this.onTimeoutError();
        }
    }

    private void onTimeoutError() {
        T view = getView();
        if (view != null) {
            view.hideProgressDialog();
            Context context = view.getContext();
            if (context != null) {
                view.showErrorAlert(context.getString(R.string.common_timeout_error));
            }
        }
    }


}