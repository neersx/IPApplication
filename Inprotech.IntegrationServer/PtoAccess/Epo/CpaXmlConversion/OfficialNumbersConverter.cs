using System;
using System.Linq;
using Notifications = Inprotech.Integration.Notifications;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using CaseDetails = CPAXML.CaseDetails;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public interface IOfficialNumbersConverter
    {
        void Convert(bibliographicdata bibliographicdata, CaseDetails caseDetails);
    }

    public class OfficialNumbersConverter : IOfficialNumbersConverter
    {
        public void Convert(bibliographicdata bibliographicdata, CaseDetails caseDetails)
        {
            var publication = ExtractPublicationReference(bibliographicdata);
            if (publication != null)
            {
                caseDetails.CreateIdentifierNumberDetails("Publication", publication.country.Text[0] + publication.docnumber.Text[0]);
                caseDetails.CreateEventDetails("Publication").EventDate = DateTime.ParseExact(publication.date.Text[0],
                    "yyyyMMdd", null).Date.ToString("yyyy-MM-dd");
            }

            var application = ExtractApplicationReference(bibliographicdata);
            if (application == null)
                return;

            caseDetails.CreateIdentifierNumberDetails("Application",
                application.country.Text[0] + application.docnumber.Text[0]);
            caseDetails.CreateEventDetails("Application").EventDate = DateTime.ParseExact(application.date.Text[0],
                "yyyyMMdd", null).Date.ToString("yyyy-MM-dd"); 
        }

        static documentid ExtractPublicationReference(bibliographicdata bibliographicdata)
        {
            if (bibliographicdata.publicationreference == null)
                return null;

            return bibliographicdata.publicationreference
                    .Where(i => i.documentid.Any(j => Notifications.Utility.IgnoreCaseEquals(j.country.Text[0], "EP")))
                    .LatestByChangeGazetteNum(i => i.changegazettenum)
                    .SelectMany(i => i.documentid)
                    .FirstOrDefault();
        }

        static documentid ExtractApplicationReference(bibliographicdata bibliographicdata)
        {
            if (bibliographicdata.applicationreference == null)
                return null;

            return bibliographicdata.applicationreference
               .Where(i => i.documentid.Any(j => Notifications.Utility.IgnoreCaseEquals(j.country.Text[0], "EP")))
               .LatestByChangeGazetteNum(i => i.changegazettenum)
               .SelectMany(i => i.documentid)
               .FirstOrDefault();
        }
    }
}