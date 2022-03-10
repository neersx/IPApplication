using System.Xml.Linq;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders
{
    public class ApplicantBuilder : IBuilder<XElement>
    {
        LegalEntityType EntityType { get; set; }

        XElement Address { get; set; }

        string SequenceNumber { get; set; }

        public string Name { get; set; }

        public XElement Build()
        {
            XElement name;

            switch (EntityType)
            {
                case LegalEntityType.Person:
                    name = new XElement(Ns.Common + "PersonName",
                                        new XElement(Ns.Common + "PersonFullName", Name ?? Fixture.String()));
                    break;

                case LegalEntityType.Organisation:
                    name = new XElement(Ns.Common + "OrganizationName",
                                        new XElement(Ns.Common + "OrganizationStandardName", Name ?? Fixture.String()));
                    break;

                default:
                    name = new XElement(Ns.Common + "EntityName", Name ?? Fixture.String());
                    break;
            }

            return new XElement(Ns.Trademark + "Applicant",
                                new XAttribute(Ns.Common + "sequenceNumber", SequenceNumber ?? string.Empty),
                                new XElement(Ns.Common + "Contact",
                                             new XElement(Ns.Common + "Name", name),
                                             Address ?? new StructuredAddressBuilder().Build())
                               );
        }

        public ApplicantBuilder AsIndividual(string personName)
        {
            EntityType = LegalEntityType.Person;
            Name = personName;
            return this;
        }

        public ApplicantBuilder AsOrganisation(string organisationName)
        {
            EntityType = LegalEntityType.Organisation;
            Name = organisationName;
            return this;
        }

        public ApplicantBuilder AsEntityName(string entityName)
        {
            EntityType = LegalEntityType.NotSet;
            Name = entityName;
            return this;
        }

        public ApplicantBuilder WithSequence(string sequenceNo)
        {
            SequenceNumber = sequenceNo;
            return this;
        }

        public ApplicantBuilder WithAddress(string addressline, string countryCode)
        {
            Address = new StructuredAddressBuilder
            {
                AddressLineText1 = addressline,
                CountryCode = countryCode
            }.Build();

            return this;
        }

        public ApplicantBuilder WithAddress(XElement address)
        {
            Address = address;

            return this;
        }

        enum LegalEntityType
        {
            Person,
            Organisation,
            NotSet
        }
    }
}