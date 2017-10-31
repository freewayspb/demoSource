public class TripDetailsActivity extends BaseProgressActivity<TripDetailsView, TripDetailsPresenter>
        implements TripDetailsView, TripCostsFragment.TripCostsFragmentListener {

    private static final int EXPAND_DURATION = 300;
    private static final int INITIAL_FRAGMENT_HEIGHT = 0;

    private ActivityTripsDetailsBinding binding;
    private TripDetailsLayoutData tripDetailsLayoutData;

    @Inject
    TripDetailsPresenter presenter;

    @Inject
    PriceFormatter priceFormatter;

    public static void start(Activity activity, String orderId) {
        Intent intent = new Intent(activity, TripDetailsActivity.class);
        intent.putExtra(EXTRA_ORDER_ID, orderId);
        activity.startActivity(intent);
    }

    @Override
    protected void injectSelf(@NonNull ActivityComponent component) {
        component.inject(this);
    }

    @Override
    protected void setFragmentContainer() {
        fragmentContainerId = R.id.flFragmentCosts;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (AccessibilityUtil.isTalkBackEnabled(this)) {
            setTitle(null);
        }
        binding = DataBindingUtil.setContentView(this, R.layout.activity_trips_details);
        binding.setPresenter(presenter);

        ExpandDetector expandDetector = new ExpandDetector(this, presenter::openTripCosts);
        binding.llExpandCosts.setOnTouchListener(expandDetector);
        binding.btnCollapseTripCosts.setOnTouchListener(expandDetector);
        binding.btnNext.setOnClickListener(v -> {
            TripCostsFragment tripCostsFragment = getFragment(TripCostsFragment.class);
            if (tripCostsFragment != null) {
                tripCostsFragment.openReports();
            }
        });
    }

    @NonNull
    @Override
    public TripDetailsPresenter createPresenter() {
        presenter.setOrderId(getIntent().getStringExtra(EXTRA_ORDER_ID));
        return presenter;
    }

    @Override
    public void showTripData(TripDetailsLayoutData tripDetailsLayoutData) {
        this.tripDetailsLayoutData = tripDetailsLayoutData;
        binding.setTrip(tripDetailsLayoutData);
        if (AccessibilityUtil.isTalkBackEnabled(this)) {
            AccessibilityUtil.hoverView(binding.tvDate);
        }
    }

    @Override
    public void onLoadOrderDetails(OrderDetails orderDetails) {
        addFragment(TripCostsFragment.newInstance(orderDetails),
                TripCostsFragment.class.getSimpleName());
    }

    @Override
    public void openTripCostDetails() {
        startTripCostDetailsAnimation(true);
    }

    @Override
    public void closeTripCostDetails() {
        startTripCostDetailsAnimation(false);
    }

    @Override
    public void openReports(String orderId) {
        ReportProblemActivity.start(this, orderId);
    }

    @Override
    public void showTripTrack(Bitmap trackBitmap) {
        binding.ivMap.setImageBitmap(trackBitmap);
    }

    @Override
    public void hideTrackProgress() {
        binding.pbMapLoader.setVisibility(View.GONE);
    }

    private void startTripCostDetailsAnimation(boolean expand) {
        int height = (int) (getResources().getDisplayMetrics().heightPixels - binding.flFragmentCosts.getY());

        int from, to;
        if (expand) {
            from = INITIAL_FRAGMENT_HEIGHT;
            to = height;
        } else {
            from = height;
            to = INITIAL_FRAGMENT_HEIGHT;
        }

        ValueAnimator heightAnimator = AnimationUtil.getHeightAnimator(binding.flFragmentCosts, from, to);
        heightAnimator.setDuration(EXPAND_DURATION);
        heightAnimator.addListener(new OpenCostsAnimationListener(expand,
                (startAnimation) -> tripDetailsLayoutData.getOpenCostDetails().set(!startAnimation)));
        heightAnimator.start();
    }

    @Override
    public void onPaymentUpdate() {
        PaymentActivity.start(this, Constants.EMPTY_STRING);
    }
}