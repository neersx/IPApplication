using System.Collections.Generic;
using System.Linq;
using CPAXML;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.PctOneTimeJob
{
    public interface IUpdateAssociatedRelationCountry
    {
        bool TryUpdate(string cpaXml, out string newCpaXml);
    }

    public class UpdateAssociatedRelationCountry : IUpdateAssociatedRelationCountry
    {
        const string PctComment = "Parent Continuity - PCT";
        const string ProvsnlComment = "This application Claims Priority from Provisional Application";

        public bool TryUpdate(string cpaXml, out string newCpaXml)
        {
            var output = CpaXmlHelper.Parse(cpaXml);

            if (!ChangeIfRequired(output))
            {
                newCpaXml = string.Empty;
                return false;
            }

            newCpaXml = CpaXmlHelper.Serialize(output);
            return true;
        }

        static bool ChangeIfRequired(Transaction cpaXmlTransaction)
        {
            var caseDetails = cpaXmlTransaction.FindFirstCaseDetail();

            var relatedCasesToBeModified = (caseDetails.AssociatedCaseDetails ?? new List<AssociatedCaseDetails>())
                .Where(_ => _.AssociatedCaseComment == PctComment || _.AssociatedCaseComment == ProvsnlComment).ToList();

            if (!relatedCasesToBeModified.Any())
                return false;

            foreach (var associatedCaseDetail in relatedCasesToBeModified)
            {
                if (associatedCaseDetail.AssociatedCaseComment == PctComment)
                {
                    associatedCaseDetail.AssociatedCaseCountryCode = "PCT";
                    continue;
                }
                if (associatedCaseDetail.AssociatedCaseComment == ProvsnlComment)
                    associatedCaseDetail.AssociatedCaseCountryCode = "US";
            }
            return true;
        }
    }
}