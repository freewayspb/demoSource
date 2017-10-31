
@RunWith(RobolectricTestRunner.class)
@Config(sdk = 21, manifest = Config.NONE)
public class ServerTripInteractorUnitTest {
    public static final String ORDER_ID = "some order id";
    public static final String TRACK_URL = "some track url";
    public static final String IMAGE_BASE64_STRING = "image string";
    public static final String FAKE_CITY_ID = "fake_city_id";

    @Mock
    TripOrderResponseData responseData;

    @Mock
    RxSocketManager socketManager;

    @Mock
    ImageUtils imageUtils;

    @Mock
    OrderDetailsResponseData orderDetailsResponseData;

    @Mock
    Bitmap bitmap;

    @Mock
    ResponseBody responseBody;

    TripInteractor interactor;

    @Before
    public void setup(){
        MockitoAnnotations.initMocks(this);
        interactor = new ServerTripInteractor(socketManager, imageUtils);

        when(imageUtils.getBitmapFromBase64Url(anyString()))
                .thenReturn(Observable.just(bitmap));

        RxJavaHooks.reset();
        RxAndroidPlugins.getInstance().reset();
        RxJavaHooks.setOnIOScheduler(scheduler -> Schedulers.immediate());
        RxAndroidPlugins.getInstance().registerSchedulersHook(new RxAndroidSchedulersHook() {
            @Override
            public Scheduler getMainThreadScheduler() {
                return Schedulers.immediate();
            }
        });
    }

    @Test
    public void getNextOrders_tripOrdersLoaded() {
        when(responseData.getTotalPages()).thenReturn(TOTAL_COUNT);
        when(responseData.getOrders()).thenReturn(setupResponseList());

        doAnswer(invocation -> Observable.just(responseData)).when(socketManager).tripsGetOrderHistory(any(TripOrderRequestData.class));

        TestSubscriber<List<TripOrderDetailsData>> subscriber = TestSubscriber.create();
        interactor.initInteractor(FAKE_CITY_ID);
        interactor.getNextOrders().subscribe(subscriber);

        subscriber.awaitTerminalEvent();
        subscriber.assertNoErrors();
        subscriber.assertCompleted();
        subscriber.assertValueCount(SINGLE_TRIP_RESPONSE);

        List<List<TripOrderDetailsData>> result = subscriber.getOnNextEvents();
        List<TripOrderDetailsData> out = result.get(0);

        assertEquals(out.size(), TRIPS_COUNT);
    }

    @Test
    public void getNextOrders_noOrdersLoaded() {
        when(responseData.getTotalPages()).thenReturn(0);
        when(responseData.getOrders()).thenReturn(new ArrayList<>());

        doAnswer(invocation -> Observable.just(responseData)).when(socketManager).tripsGetOrderHistory(any(TripOrderRequestData.class));

        TestSubscriber<List<TripOrderDetailsData>> subscriber = TestSubscriber.create();
        interactor.initInteractor(FAKE_CITY_ID);
        interactor.getNextOrders().repeat(2).subscribe(subscriber);
        interactor.getNextOrders();

        verify(socketManager, times(1)).tripsGetOrderHistory(any(TripOrderRequestData.class));
    }

    @Test
    public void getNextOrders_loadFailed() {
        doAnswer(invocation -> Observable.error(new RuntimeException())).when(socketManager).tripsGetOrderHistory(any(TripOrderRequestData.class));

        TestSubscriber<List<TripOrderDetailsData>> subscriber = TestSubscriber.create();
        interactor.initInteractor(FAKE_CITY_ID);
        interactor.getNextOrders().subscribe(subscriber);

        subscriber.awaitTerminalEvent();
        subscriber.assertError(RuntimeException.class);
    }

    @Test
    public void deleteOrder_orderDeleted() {
        doAnswer(invocation -> Observable.empty()).when(socketManager).tripsDeleteOrder(any(TripOrderIdRequestData.class));

        TestSubscriber<Boolean> subscriber = TestSubscriber.create();
        interactor.initInteractor(FAKE_CITY_ID);
        interactor.deleteOrder(anyString()).subscribe(subscriber);

        subscriber.awaitTerminalEvent();
        subscriber.assertNoErrors();
        subscriber.assertCompleted();
    }

    @Test
    public void deleteOrder_deleteFailed() {
        doAnswer(invocation -> Observable.error(new RuntimeException())).when(socketManager).tripsDeleteOrder(any(TripOrderIdRequestData.class));

        TestSubscriber<Boolean> subscriber = TestSubscriber.create();
        interactor.initInteractor(FAKE_CITY_ID);
        interactor.deleteOrder(anyString()).subscribe(subscriber);

        subscriber.awaitTerminalEvent();
        subscriber.assertError(RuntimeException.class);
    }

    private List<TripOrderDetailsData> setupResponseList() {
        List<TripOrderDetailsData> list = new ArrayList<>(TRIPS_COUNT);
        for (int i = 0; i < TRIPS_COUNT; i++) {
            list.add(new TripOrderDetailsData());
        }

        return list;
    }

    @Test
    public void getOrderDetails_success(){
        when(socketManager.tripsGetOrderDetails(any(TripOrderDetailsRequestData.class)))
                .thenReturn(Observable.just(orderDetailsResponseData));

        interactor.getOrderDetails(ORDER_ID);

        verify(socketManager).tripsGetOrderDetails(any(TripOrderDetailsRequestData.class));
    }

    @Test
    public void getOrderDetails_failed(){
        when(socketManager.tripsGetOrderDetails(any(TripOrderDetailsRequestData.class)))
                .thenReturn(Observable.error(new Exception()));

        TestSubscriber<OrderDetailsResponseData> testSubscriber = TestSubscriber.create();
        interactor.getOrderDetails(ORDER_ID).subscribe(testSubscriber);

        testSubscriber.awaitTerminalEvent();
        testSubscriber.assertError(Exception.class);
    }

    @Test
    public void getTripTrackImage_success() throws IOException{


        TestSubscriber<Bitmap> testSubscriber = TestSubscriber.create();
        interactor.getTripTrackImage(TRACK_URL).subscribe(testSubscriber);

        testSubscriber.awaitTerminalEvent();
        testSubscriber.assertNoErrors();
    }

    @Test
    public void getTripTrackImage_failedImageLoading() throws IOException{
        when(imageUtils.getBitmapFromBase64Url(anyString()))
                .thenReturn(Observable.error(new Exception()));

        TestSubscriber<Bitmap> testSubscriber = TestSubscriber.create();
        interactor.getTripTrackImage(TRACK_URL).subscribe(testSubscriber);

        testSubscriber.awaitTerminalEvent();
        testSubscriber.assertError(Exception.class);
    }
}