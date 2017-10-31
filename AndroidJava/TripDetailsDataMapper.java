
public class TripDetailsDataMapper implements Func1<OrderDetailsResponseData, TripDetailsLayoutData> {
    public static final int USER_RATING_HIGH = 5;

    private PriceFormatter priceFormatter;
    private RegionUtil regionUtil;

    @Inject
    public TripDetailsDataMapper(PriceFormatter priceFormatter, RegionUtil regionUtil) {
        this.priceFormatter = priceFormatter;
        this.regionUtil = regionUtil;
    }

    private TripDetailsLayoutData convertResponseToViewModel(OrderDetailsResponseData orderDetailsResponseData) {
        TripDetailsLayoutData tripDetailsLayoutData = new TripDetailsLayoutData();

        OrderDetails orderDetails = orderDetailsResponseData.getOrderDetails();

        tripDetailsLayoutData.setCanceled(orderDetails.isCancelled());
        tripDetailsLayoutData.setTrackUrl(orderDetails.getTrackUrl());
        //Header
        Date tripDate = orderDetails.getStartDate();
        tripDetailsLayoutData.setDate(DateUtils.formatTitleDate(tripDate));
        tripDetailsLayoutData.setStartTime(DateUtils.formatTime(tripDate));
        tripDetailsLayoutData.setStartLocation(orderDetails.getStartAddress());
        tripDetailsLayoutData.setEndTime(DateUtils.formatTime(orderDetails.getEndDate()));

        String endAddress = orderDetails.getEndAddress();
        tripDetailsLayoutData.setEndLocation(TextUtils.isEmpty(endAddress) ? null : endAddress);

        //Cost
        TripCost tripCost = orderDetails.getTripCost();
        long total = tripCost == null ? orderDetails.getCancelationCost() : tripCost.getTotal();
        tripDetailsLayoutData.setCostText(priceFormatter.formatPriceWithoutDecimals(total));

        //Driver info
        DriverInfo driverInfo = orderDetails.getDriverInfo();
        tripDetailsLayoutData.setDriverName(driverInfo.getFirstName());
        tripDetailsLayoutData.setDriverFullName(driverInfo.getFirstName() + Constants.SPACE + driverInfo.getLastName());
        tripDetailsLayoutData.setDriverRating(driverInfo.getFormattedRating());

        OrderRating rating = orderDetails.getRating();
        tripDetailsLayoutData.setDriverLike(rating != null && rating.getCustomerRating() == USER_RATING_HIGH);

        //Car info
        CarInfo carInfo = orderDetails.getCarInfo();
        tripDetailsLayoutData.setCarName(carInfo.getBrand() + " " + carInfo.getModel());
        tripDetailsLayoutData.setCarColorText(carInfo.getColor());
        tripDetailsLayoutData.setCarColorRgb(ColorParser.parseColor(carInfo.getColor(), regionUtil.getCountryRegion()));
        tripDetailsLayoutData.setCarCapacity(orderDetails.getCarCapacity());

        //Accessibility
        tripDetailsLayoutData.setAccessibilityTitleDate(DateUtils.format(DateUtils.ACCESSIBILITY_DATE_FORMAT, tripDate));

        return tripDetailsLayoutData;
    }

    @Override
    public TripDetailsLayoutData call(OrderDetailsResponseData orderDetailsResponseData) {
        return convertResponseToViewModel(orderDetailsResponseData);
    }
}