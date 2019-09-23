package gov.va.bip.origin.transform.impl;

import gov.va.bip.framework.transfer.transform.AbstractProviderToDomain;
import gov.va.bip.origin.api.model.v1.SampleRequest;
import gov.va.bip.origin.model.SampleDomainRequest;

/**
 * Transform a REST Provider {@link SampleRequest} into a service Domain {@link SampleDomainRequest} object.
 *
 * @author aburkholder
 */
public class SampleByPidProviderToDomain extends AbstractProviderToDomain<SampleRequest, SampleDomainRequest> {

	/**
	 * Transform a REST Provider {@link SampleRequest} into a service Domain {@link SampleDomainRequest} object.
	 * <p>
	 * {@inheritDoc AbstractProviderToDomain}
	 */
	@Override
	public SampleDomainRequest convert(SampleRequest domainObject) {
		SampleDomainRequest providerObject = new SampleDomainRequest();
		if (domainObject != null) {
			providerObject.setParticipantID(domainObject.getParticipantID());
		}
		return providerObject;
	}

}
