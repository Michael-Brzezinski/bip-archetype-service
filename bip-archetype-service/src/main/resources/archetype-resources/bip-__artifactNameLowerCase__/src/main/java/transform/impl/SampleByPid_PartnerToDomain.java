#set( $symbol_pound = '#' )
#set( $symbol_dollar = '$' )
#set( $symbol_escape = '\' )
package gov.va.bip.${artifactNameLowerCase}.transform.impl;

/**
 * Transform a Partner client response object to a service Domain response object.
 * Partner data classes are typically generated by XJC, Swagger CodeGen or similar
 * from the WSDL or XSD provided by the partner.
 */
public class SampleByPid_PartnerToDomain {
	/* as shown below, partner-to-domain transform classes must extend AbstractDomainToPartner */
//	extends AbstractPartnerToDomain<SomePartnerResponse, SomeDomainResponse>

	/** The object factory derived by XJC (or similar) for partner client data objects. */
//	protected static final ObjectFactory OBJECT_FACTORY = new ObjectFactory();

	/**
	 * Transform a Partner response into a service Domain response object.
	 * <br/>
	 * <b>Some objects inside the returned response may be {@code null}.</b>
	 * <p>
	 * {@inheritDoc AbstractPartnerToDomain}
	 */
//	@Override
//	public SomeDomainResponse convert(SomePartnerResponse partnerObject) {
//		SomeDomainResponse domainObject = new SomeDomainResponse();
//
//		if (partnerObject != null && partnerObject.getSomeInternalObject() != null) {
//			SomeDomainObject domainData = new SomeDomainObject();
//
//			domainData.setSomeValue(partnerObject.getSomeInternalObject().getSomeValue());
//			/// etc...
//
//			domainObject.setDomainData(domainData);
//		}
//
//		return domainObject;
//	}
}
