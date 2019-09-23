package gov.va.bip.origin.utils;

/**
 * The Class HystrixCommandConstants.
 */
public final class HystrixCommandConstants {

	/** Origin Service Thread Pool Group. */
	public static final String ORIGIN_SERVICE_GROUP_KEY = "OriginServiceGroup";

	/**
	 * Do not instantiate
	 */
	private HystrixCommandConstants() {
		throw new UnsupportedOperationException("HystrixCommandConstants is a static class. Do not instantiate it.");
	}
}