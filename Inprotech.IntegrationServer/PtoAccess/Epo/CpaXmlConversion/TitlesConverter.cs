using System;
using System.Collections.Generic;
using System.Linq;
using Notifications = Inprotech.Integration.Notifications;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using CaseDetails = CPAXML.CaseDetails;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public interface ITitlesConverter
    {
        void Convert(worldpatentdata patentData, bibliographicdata bibliographicdata, CaseDetails caseDetails);
    }

    public class TitlesConverter : ITitlesConverter
    {
        public void Convert(worldpatentdata patentData, bibliographicdata bibliographicdata, CaseDetails caseDetails)
        {
            var proceedingLanguage = ExtractProceedingLanguage(patentData);
            if (string.IsNullOrEmpty(proceedingLanguage))
                return;

            var inventionTitles = ExtractInventionTitles(bibliographicdata);
            if (inventionTitles == null)
                return;

            inventiontitle title = null;

            if (!string.IsNullOrEmpty(proceedingLanguage))
            {
                title = inventionTitles.SingleOrDefault(i => Notifications.Utility.IgnoreCaseEquals(proceedingLanguage, i.lang));
            }

            if (title == null)
            {
                title = inventionTitles.SingleOrDefault(i => string.IsNullOrEmpty(i.lang));
            }

            if (title == null)
            {
                title = inventionTitles.SingleOrDefault(i => Notifications.Utility.IgnoreCaseEquals("en", i.lang));
            }

            if (title == null)
            {
                title = inventionTitles.FirstOrDefault();
            }

            if (title != null)
            {
                caseDetails.CreateDescriptionDetails("Short Title", string.Join(Environment.NewLine, title.Text),
                    title.lang);
            }
        }

        static string ExtractProceedingLanguage(worldpatentdata patentData)
        {
            return patentData.registersearch
                    .registerdocuments
                    .SelectMany(i => i.registerdocument)
                    .SelectMany(i => i.proceduraldata)
                    .SelectMany(i => i.proceduralstep)
                    .Where(i => Notifications.Utility.IgnoreCaseEquals(i.proceduralstepcode.Text[0], "PROL"))
                    .SelectMany(i => i.proceduralsteptext)
                    .Where(i => Notifications.Utility.IgnoreCaseEquals(i.steptexttype, "procedure language"))
                    .Select(i => i.Text[0])
                    .SingleOrDefault();
        }

        static IList<inventiontitle> ExtractInventionTitles(bibliographicdata bibliographicdata)
        {
            return bibliographicdata.inventiontitle
                .GroupBy(i => i.lang)
                .SelectMany(g => g.LatestByChangeGazetteNum(i => i.changegazettenum))
                .ToList();
        }
    }
}
