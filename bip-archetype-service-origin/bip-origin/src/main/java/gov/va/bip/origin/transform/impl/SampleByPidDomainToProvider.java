package gov.va.bip.origin.transform.impl;

import gov.va.bip.framework.transfer.transform.AbstractDomainToProvider;
import gov.va.bip.origin.api.model.v1.SampleInfo;
import gov.va.bip.origin.api.model.v1.SampleResponse;
import gov.va.bip.origin.model.SampleDomainResponse;

/**
 * Transform a service Domain {@link SampleDomainResponse} into a REST Provider {@link SampleResponse} object.
 *
 * @author aburkholder
 */
public class SampleByPidDomainToProvider extends AbstractDomainToProvider<SampleDomainResponse, SampleResponse> {

	/**
	 * Transform a service Domain {@link SampleDomainResponse} into a REST Provider {@link SampleResponse} object.
	 * <br/>
	 * <b>Member objects inside the returned object may be {@code null}.</b>
	 * <p>
	 * {@inheritDoc AbstractDomainToProvider}
	 */
	@Override
	public SampleResponse convert(SampleDomainResponse domainObject) {
		SampleResponse providerObject = new SampleResponse();

		// add data
		SampleInfo providerData = new SampleInfo();
		if (domainObject != null && domainObject.getSampleInfo() != null) {
			providerData.setName(domainObject.getSampleInfo().getName());
			providerData.setParticipantId(domainObject.getSampleInfo().getParticipantId());
		}
		providerObject.setSampleInfo(providerData);
		// add messages
		if (domainObject != null && domainObject.getMessages() != null && !domainObject.getMessages().isEmpty()) {
			for (gov.va.bip.framework.messages.ServiceMessage domainMsg : domainObject.getMessages()) {
				providerObject.addMessage(domainMsg.getSeverity(), domainMsg.getKey(), domainMsg.getText(),
						domainMsg.getHttpStatus());
			}
		}

		return providerObject;
	}
}
