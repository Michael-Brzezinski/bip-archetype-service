package gov.va.bip.origin.messages;

import java.util.Locale;

import org.springframework.context.support.ReloadableResourceBundleMessageSource;

import gov.va.bip.framework.messages.MessageKey;

/**
 * The source for messages generated by the micro-service code.
 *
 * @author aburkholder
 */
public enum OriginMessageKeys implements MessageKey {

	/** Minimum allowed value validation for PID; no args */
	BIP_SAMPLE_REQUEST_PID_MIN("Min.sampleRequest.participantID",
			"SampleRequest.participantID cannot be zero"),
	/** PID cannot be null validation; no args */
	BIP_SAMPLE_REQUEST_PID_NOTNULL("NotNull.sampleRequest.participantID",
			"SampleRequest.participantID cannot be null"),
	/** Payload cannot be null validation; no args */
	BIP_SAMPLE_REQUEST_NOTNULL("NotNull.sampleRequest",
			"SampleRequest Payload cannot be null"),
	/** Response has different PID than the request; no args */
	BIP_SAMPLE_REQUEST_PID_INCONSISTENT("bip.origin.sample.request.pid.inconsistent",
			"Response returned an invalid Participant ID."),
	/** Response has different PID than the logged in user; no args */
	BIP_SAMPLE_REQUEST_PID_INVALID("bip.origin.sample.request.pid.invalid",
			"Response has different PID than the logged in user."),
	BIP_SAMPLE_SERVICE_IMPL_RESPONDED_WITH_MOCK_DATA("bip.origin.sample.service.impl.responded.with.mock.data",
			"Response sent from service impl with mock data.");

	/** The filename "name" part of the properties file to get from the classpath */
	private static final String propertiesFile = "messages";
	/** The message source containing properties for this enum */
	private static ReloadableResourceBundleMessageSource messageSource;
	/* Populate the message source from the properties file */
	static {
		messageSource = new ReloadableResourceBundleMessageSource();
		messageSource.setBasename("classpath:" + propertiesFile);
		messageSource.setDefaultEncoding("UTF-8");
	}

	/** The key - must be identical to the key in framework-messages.properties */
	private String key;
	/** A default message, in case the key is not found in framework-messages.properties */
	private String defaultMessage;

	/**
	 * Construct keys with their property file counterpart key and a default message.
	 *
	 * @param key - the key as declared in the properties file
	 * @param defaultMessage - in case the key cannot be found
	 */
	private OriginMessageKeys(final String key, final String defaultMessage) {
		this.key = key;
		this.defaultMessage = defaultMessage;
	}

	/*
	 * (non-Javadoc)
	 *
	 * @see gov.va.bip.framework.messages.MessageKey#getKey()
	 */
	@Override
	public String getKey() {
		return this.key;
	}

	/*
	 * (non-Javadoc)
	 *
	 * @see gov.va.bip.framework.messages.MessageKey#getMessage(java.lang.Object[])
	 */
	@Override
	public String getMessage(final String... params) {
		return messageSource.getMessage(this.getKey(), params, this.defaultMessage, Locale.getDefault());
	}
	
}
