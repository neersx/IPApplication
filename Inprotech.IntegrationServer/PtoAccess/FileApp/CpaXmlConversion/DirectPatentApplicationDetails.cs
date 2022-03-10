using CPAXML;
using Inprotech.Integration.IPPlatform.FileApp.Models;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion
{
    public class DirectPatentApplicationDetails : IApplicationDetailsConverter
    {
        public void Extract(CaseDetails caseDetails, FileCase fileCase, FileCase inprotech)
        {
            var priorityDetails = caseDetails.CreateAssociatedCaseDetails("PRIORITY");
            var priorityNumber = fileCase.BibliographicalInformation.PriorityNumber ?? inprotech.BibliographicalInformation.PriorityNumber;
            var priorityDate = fileCase.BibliographicalInformation.PriorityDate ?? inprotech.BibliographicalInformation.PriorityDate;
            var priorityCountry = fileCase.BibliographicalInformation.PriorityCountry ?? inprotech.BibliographicalInformation.PriorityCountry;

            priorityDetails.AssociatedCaseCountryCode = priorityCountry;
            
            if (!string.IsNullOrWhiteSpace(priorityNumber))
            {
                priorityDetails.CreateIdentifierNumberDetails("FOREIGN PRIORITY", priorityNumber);
            }

            if (!string.IsNullOrWhiteSpace(priorityDate))
            {
                var application = priorityDetails.CreateEventDetails("EARLIEST PRIORITY");

                application.EventDate = priorityDate;
            }
        }
    }
}