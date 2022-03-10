using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public interface IPriorityClaimsConverter
    {
        void Convert(bibliographicdata bibliographicdata, CaseDetails caseDetails);
    }

    public class PriorityClaimsConverter : IPriorityClaimsConverter
    {
        public void Convert(bibliographicdata bibliographicdata, CaseDetails caseDetails)
        {
            var priorityClaims = ExtractPriorityClaims(bibliographicdata);
            if (priorityClaims == null)
                return;

            foreach (var claim in priorityClaims)
            {
                string identifierNo = null;
                if (claim.docnumber != null && claim.docnumber.Text != null && claim.docnumber.Text.Any())
                {
                    if (claim.docnumber.Text[0] == "deleted")
                        continue;
                    identifierNo = claim.docnumber.Text[0];
                }

                var details = caseDetails.CreateAssociatedCaseDetails("Priority");
                details.AssociatedCaseCountryCode = claim.country.Text != null ? claim.country.Text[0] : string.Empty;
                if (!string.IsNullOrEmpty(identifierNo))
                    details.CreateIdentifierNumberDetails("Priority", identifierNo);
                details.CreateEventDetails("Priority").EventDate = claim.date.Text != null
                    ? DateTime.ParseExact(claim.date.Text[0], "yyyyMMdd", null).ToString("yyyy-MM-dd")
                    : string.Empty;
            }
        }

        static IEnumerable<priorityclaim> ExtractPriorityClaims(bibliographicdata bibliographicdata)
        {
            if (bibliographicdata.priorityclaims == null)
                return null;

            return bibliographicdata.priorityclaims
                .LatestByChangeGazetteNum(i => i.changegazettenum)
                .SelectMany(i => i.priorityclaim);
        }
    }
}
