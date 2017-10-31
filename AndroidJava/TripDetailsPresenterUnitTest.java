
@RunWith(RobolectricTestRunner.class)
@Config(sdk = 21, manifest = Config.NONE)
public class TripDetailsPresenterUnitTest extends BasePresenterTest{
    public static final String ORDER_ID = "45";
    public static final String TRACK_URL = "http://fakeurl.com";
    public static final int BITMAP_SIZE = 50;
    public static final String USER_ERROR_DESC = "User action failed";
    public static final String TIMEOUT_ERROR = "Timeout";

    @Mock
    TripDetailsLayoutData tripDetailsLayoutData;

    @Mock
    TripCostLayoutData tripCostLayoutData;

    @Mock
    TripDetailsView view;

    @Mock
    TripInteractor tripInteractor;

    @Mock
    TripDetailsDataMapper tripDetailsDataMapper;

    @Mock
    OrderDetailsResponseData orderDetailsResponseData;

    @Mock
    SocketError socketError;

    private TripDetailsPresenter presenter;

    private Observable<Bitmap> bitmapObservable;


    @Before
    public void setup(){
        MockitoAnnotations.initMocks(this);

        presenter = new TripDetailsPresenter(tripInteractor, tripDetailsDataMapper);
        presenter.setOrderId(ORDER_ID);

        OrderDetails orderDetails = new OrderDetails();
        orderDetails.setTrackUrl(TRACK_URL);
        when(orderDetailsResponseData.getOrderDetails()).thenReturn(orderDetails);

        bitmapObservable = Observable.just(Bitmap.createBitmap(BITMAP_SIZE, BITMAP_SIZE, Bitmap.Config.ARGB_8888));
        when(tripInteractor.getTripTrackImage(TRACK_URL)).thenReturn(bitmapObservable);
        when(tripDetailsLayoutData.getTrackUrl()).thenReturn(TRACK_URL);

        when(tripInteractor.getOrderDetails(anyString())).thenReturn(Observable.just(orderDetailsResponseData));
        when(tripDetailsDataMapper.call(orderDetailsResponseData)).thenReturn(tripDetailsLayoutData);
    }

    @Test
    public void attachView_success(){
        presenter.attachView(view);

        verify(view).onShowProgressDialog();
        verify(view).onDismissProgressDialog();
        verify(view).showTripData(any(TripDetailsLayoutData.class));
        verify(view).showTripTrack(any(Bitmap.class));
    }

    @Test
    public void attachView_noTrackUrl(){
        when(tripDetailsLayoutData.getTrackUrl()).thenReturn(null);
        presenter.attachView(view);

        verify(view).showTripData(any(TripDetailsLayoutData.class));
        verify(view, never()).showTripTrack(any(Bitmap.class));
    }

    @Test
    public void attachView_getOrderDetailsUserError(){
        when(socketError.getErrorDesc()).thenReturn(USER_ERROR_DESC);
        when(tripInteractor.getOrderDetails(anyString()))
                .thenReturn(Observable.error(new SocketErrorException(socketError)));

        presenter.attachView(view);

        verify(view).showError(USER_ERROR_DESC);
        verify(view, never()).showTripData(tripDetailsLayoutData);
    }

    @Test
    public void attachView_getOrderDetailsTimeoutError(){
        when(tripInteractor.getOrderDetails(anyString()))
                .thenReturn(Observable.error(new TimeoutException()));
        when(view.getContext()).thenReturn(mockContext);
        when(mockContext.getString(R.string.common_timeout_error)).thenReturn(TIMEOUT_ERROR);
        presenter.attachView(view);

        verify(view).showError(TIMEOUT_ERROR);
        verify(view, never()).showTripData(eq(tripDetailsLayoutData));
    }

    @Test
    public void openTripCosts_expand(){
        presenter.attachView(view);
        presenter.openTripCosts(true);

        verify(view).openTripCostDetails();
    }

    @Test
    public void openTripCosts_collapse(){
        presenter.attachView(view);
        presenter.openTripCosts(false);

        verify(view).closeTripCostDetails();
    }

    @Test
    public void openTripCosts_noAttachedView(){
        presenter.openTripCosts(false);

        verify(view, never()).openTripCostDetails();
        verify(view, never()).closeTripCostDetails();
    }

    @Test
    public void openReports_opened() {
        presenter.attachView(view);
        presenter.openReports();
        verify(view, atLeastOnce()).openReports(anyString());
    }
}