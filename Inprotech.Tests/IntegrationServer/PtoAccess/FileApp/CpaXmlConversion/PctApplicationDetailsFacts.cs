using System.Linq;
using CPAXML;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion
{
    public class PctApplicationDetailsFacts
    {
        [Fact]
        public void CreatePriorityDetails()
        {
            var fileCase = new FileCase
            {
                BibliographicalInformation = new Biblio
                {
                    ApplicationNumber = Fixture.String(),
                    ApplicationDate = Fixture.Date().ToString("yyyy-MM-dd"),
                    PublicationNumber = Fixture.String(),
                    PublicationDate = Fixture.Date().ToString("yyyy-MM-dd")
                }
            };

            var caseDetails = new CaseDetails(Fixture.String(), Fixture.String());
            var subject = new PctApplicationDetails();

            subject.Extract(caseDetails, new FileCase(), fileCase);

            var b = fileCase.BibliographicalInformation;
            var r = caseDetails.AssociatedCaseDetails.Single();

            Assert.Equal("PCT APPLICATION", r.AssociatedCaseRelationshipCode);
            Assert.Equal(b.ApplicationDate, r.AssociatedCaseEventDetails.Single(_ => _.EventCode == "APPLICATION").EventDate);
            Assert.Equal(b.ApplicationNumber, r.AssociatedCaseIdentifierNumberDetails.Single(_ => _.IdentifierNumberCode == "APPLICATION").IdentifierNumberText);
            Assert.Equal(b.PublicationDate, r.AssociatedCaseEventDetails.Single(_ => _.EventCode == "PUBLICATION").EventDate);
            Assert.Equal(b.PublicationNumber, r.AssociatedCaseIdentifierNumberDetails.Single(_ => _.IdentifierNumberCode == "PUBLICATION").IdentifierNumberText);
        }
    }
}