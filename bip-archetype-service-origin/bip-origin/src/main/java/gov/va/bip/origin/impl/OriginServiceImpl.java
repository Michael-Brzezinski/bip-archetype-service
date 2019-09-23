package gov.va.bip.origin.impl;

import javax.annotation.PostConstruct;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

import com.netflix.hystrix.contrib.javanica.annotation.DefaultProperties;
import com.netflix.hystrix.contrib.javanica.annotation.HystrixCommand;

import gov.va.bip.framework.cache.BipCacheUtil;
import gov.va.bip.framework.exception.BipException;
import gov.va.bip.framework.exception.BipRuntimeException;
import gov.va.bip.framework.log.BipLogger;
import gov.va.bip.framework.log.BipLoggerFactory;
import gov.va.bip.framework.messages.MessageKeys;
import gov.va.bip.framework.messages.MessageSeverity;
import gov.va.bip.origin.OriginService;
import gov.va.bip.origin.messages.OriginMessageKeys;
import gov.va.bip.origin.model.SampleDomainRequest;
import gov.va.bip.origin.model.SampleDomainResponse;
import gov.va.bip.origin.model.SampleInfoDomain;
import gov.va.bip.origin.utils.CacheConstants;
import gov.va.bip.origin.utils.HystrixCommandConstants;

/**
 * Implementation class for the Origin Service.
 * It is recommended to implement the hystrix circuit breaker pattern.
 * When there is a failure the fallback method is invoked and the response is
 * returned from the cache
 *
 * @author akulkarni
 */
@Service(value = OriginServiceImpl.BEAN_NAME)
@Component
@Qualifier("ORIGIN_SERVICE_IMPL")
@RefreshScope
@DefaultProperties(groupKey = HystrixCommandConstants.ORIGIN_SERVICE_GROUP_KEY)
public class OriginServiceImpl implements OriginService {
	private static final BipLogger LOGGER = BipLoggerFactory.getLogger(OriginServiceImpl.class);

	/** Bean name constant */
	public static final String BEAN_NAME = "originServiceImpl";

	/** The cache manager (redis implementation) */
	@Autowired
	private CacheManager cacheManager;

	/**
	 * Viability checks before the application is put into service.
	 */
	@PostConstruct
	void postConstruct() {
	}

	/**
	 * Implementation of the service (domain) layer API.
	 * <p>
	 * If graceful degredation is possible, add
	 * {@code fallbackMethod = "sampleFindByParticipantIDFallBack"}
	 * to the {@code @HystrixCommand}.
	 * <p>
	 * {@inheritDoc}
	 *
	 */
	@Override
	@CachePut(value = CacheConstants.CACHENAME_ORIGIN_SERVICE,
			key = "#root.methodName + T(gov.va.bip.framework.cache.BipCacheUtil).createKey(#sampleDomainRequest.participantID)",
			unless = "T(gov.va.bip.framework.cache.BipCacheUtil).checkResultConditions(#result)")
	/* If a fallback position is possible, add attribute to @HystrixCommand: fallback="fallbackMethodName" */
	@HystrixCommand(commandKey = "SampleFindByParticipantIDCommand",
			ignoreExceptions = { IllegalArgumentException.class, BipException.class, BipRuntimeException.class })
	public SampleDomainResponse sampleFindByParticipantID(final SampleDomainRequest sampleDomainRequest) {

		String cacheKey = "sampleFindByParticipantID" + BipCacheUtil.createKey(sampleDomainRequest.getParticipantID());

		// try from cache
		SampleDomainResponse response = new SampleDomainResponse();
		try {
			Cache cache = null;
			if ((cacheManager != null) && ((cache = cacheManager.getCache(CacheConstants.CACHENAME_ORIGIN_SERVICE)) != null)
					&& (cache.get(cacheKey) != null)) {
				LOGGER.debug("sampleFindByParticipantID returning cached data");
				response = cache.get(cacheKey, SampleDomainResponse.class);
				return response;
			}
		} catch (Exception e) {
			LOGGER.error(e.getMessage(), e);
		}

		LOGGER.debug("sampleFindByParticipantID no cached data found");

		// send hard coded data ... normally would get from db or partner
		SampleInfoDomain sampleInfoDomain = new SampleInfoDomain();
		sampleInfoDomain.setName("JANE DOE");
		sampleInfoDomain.setParticipantId(sampleDomainRequest.getParticipantID());
		response.setSampleInfo(sampleInfoDomain);
		response.addMessage(MessageSeverity.INFO, HttpStatus.OK, OriginMessageKeys.BIP_SAMPLE_SERVICE_IMPL_RESPONDED_WITH_MOCK_DATA,
				"");
		return response;
	}

	/**
	 * Support graceful degradation in a Hystrix command by adding a fallback method that Hystrix will call to obtain a
	 * default value or values in case the main command fails for {@link #sampleFindByParticipantID(SampleDomainRequest)}.
	 * <p>
	 * See {https://github.com/Netflix/Hystrix/wiki/How-To-Use#fallback} for Hystrix Fallback usage
	 * <p>
	 * Hystrix doesn't REQUIRE you to set this method. However, if it is possible to degrade gracefully
	 * - perhaps by returning static data, or performing some other process - the degraded process should
	 * be performed in the fallback method. In order to enable a fallback such as this, on the main method,
	 * add to its {@code @HystrixCommand} the {@code fallbackMethod} attribute. So for
	 * {@link #sampleFindByParticipantID(SampleDomainRequest)}
	 * you would add the attribute to its {@code @HystrixCommand}:<br/>
	 *
	 * <pre>
	 * fallbackMethod = "sampleFindByParticipantIDFallBack"
	 * </pre>
	 *
	 * <b>Note that exceptions should not be thrown from any fallback method.</b>
	 * It will "confuse" Hystrix and cause it to throw an HystrixRuntimeException.
	 * <p>
	 *
	 * @param sampleDomainRequest The request from the Java Service.
	 * @param throwable the throwable
	 * @return A JAXB element for the WS request
	 */
	@HystrixCommand(commandKey = "SampleFindByParticipantIDFallBackCommand")
	public SampleDomainResponse sampleFindByParticipantIDFallBack(final SampleDomainRequest sampleDomainRequest,
			final Throwable throwable) {
		LOGGER.info("sampleFindByParticipantIDFallBack has been activated");

		/*
		 * Fallback Method for Demonstration Purpose. In this use case, there is no static / mock data
		 * that can be sent back to the consumers. Hence the method isn't configured as fallback.
		 *
		 * If needed to be configured, add annotation to the implementation method "findPersonByParticipantID" as below
		 *
		 * @HystrixCommand(fallbackMethod = "findPersonByParticipantIDFallBack")
		 */
		final SampleDomainResponse response = new SampleDomainResponse();
		response.setDoNotCacheResponse(true);

		if (throwable != null) {
			LOGGER.debug(ReflectionToStringBuilder.toString(throwable, null, true, true, Throwable.class));
			response.addMessage(MessageSeverity.WARN, HttpStatus.OK, MessageKeys.BIP_GLOBAL_GENERAL_EXCEPTION,
					throwable.getClass().getSimpleName(), throwable.getLocalizedMessage());
		} else {
			LOGGER.error(
					"sampleFindByParticipantIDFallBack No Throwable Exception. Just Raise Runtime Exception {}",
					sampleDomainRequest);
			response.addMessage(MessageSeverity.WARN, HttpStatus.OK, MessageKeys.WARN_KEY,
					"There was a problem processing your request.");
		}
		return response;
	}
}