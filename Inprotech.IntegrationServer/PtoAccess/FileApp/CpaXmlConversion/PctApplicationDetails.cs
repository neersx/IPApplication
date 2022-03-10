using CPAXML;
using Inprotech.Integration.IPPlatform.FileApp.Models;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion
{
    public class PctApplicationDetails : IApplicationDetailsConverter
    {
        public void Extract(CaseDetails caseDetails, FileCase fileCase, FileCase inprotech)
        {
            var pctApplicationDetails = caseDetails.CreateAssociatedCaseDetails("PCT APPLICATION");
            var applicationNumber = fileCase.BibliographicalInformation.ApplicationNumber ?? inprotech.BibliographicalInformation.ApplicationNumber;
            var applicationDate = fileCase.BibliographicalInformation.ApplicationDate ?? inprotech.BibliographicalInformation.ApplicationDate;
            var publicationNumber = fileCase.BibliographicalInformation.PublicationNumber ?? inprotech.BibliographicalInformation.PublicationNumber;
            var publicationDate = fileCase.BibliographicalInformation.PublicationDate ?? inprotech.BibliographicalInformation.PublicationDate;

            pctApplicationDetails.AssociatedCaseCountryCode = "PCT";
            
            if (!string.IsNullOrWhiteSpace(applicationNumber))
            {
                pctApplicationDetails.CreateIdentifierNumberDetails("APPLICATION", applicationNumber);
            }

            if (!string.IsNullOrWhiteSpace(applicationDate))
            {
                var application = pctApplicationDetails.CreateEventDetails("APPLICATION");

                application.EventDate = applicationDate;
            }
            
            if (!string.IsNullOrWhiteSpace(publicationNumber))
            {
                pctApplicationDetails.CreateIdentifierNumberDetails("PUBLICATION", publicationNumber);
            }

            if (!string.IsNullOrWhiteSpace(publicationDate))
            {
                var publication = pctApplicationDetails.CreateEventDetails("PUBLICATION");

                publication.EventDate = publicationDate;
            }
        }
    }
}