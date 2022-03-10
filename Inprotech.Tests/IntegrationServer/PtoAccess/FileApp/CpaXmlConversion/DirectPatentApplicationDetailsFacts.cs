using System.Linq;
using CPAXML;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion
{
    public class DirectPatentApplicationDetailsFacts
    {
        [Fact]
        public void CreatePriorityDetails()
        {
            var fileCase = new FileCase
            {
                BibliographicalInformation = new Biblio
                {
                    PriorityNumber = Fixture.String(),
                    PriorityCountry = Fixture.String(),
                    PriorityDate = Fixture.Date().ToString("yyyy-MM-dd")
                }
            };

            var caseDetails = new CaseDetails(Fixture.String(), Fixture.String());
            var subject = new DirectPatentApplicationDetails();

            subject.Extract(caseDetails, new FileCase(), fileCase);

            var b = fileCase.BibliographicalInformation;
            var r = caseDetails.AssociatedCaseDetails.Single();

            Assert.Equal("PRIORITY", r.AssociatedCaseRelationshipCode);
            Assert.Equal(b.PriorityCountry, r.AssociatedCaseCountryCode);
            Assert.Equal(b.PriorityDate, r.AssociatedCaseEventDetails.Single(_ => _.EventCode == "EARLIEST PRIORITY").EventDate);
            Assert.Equal(b.PriorityNumber, r.AssociatedCaseIdentifierNumberDetails.Single(_ => _.IdentifierNumberCode == "FOREIGN PRIORITY").IdentifierNumberText);
        }
    }
}