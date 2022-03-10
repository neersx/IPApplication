using System;
using CPAXML;

namespace Inprotech.Integration.Innography
{
    public interface IInnographyIdFromCpaXml
    {
        string Resolve(string cpaXml);
    }

    public class InnographyIdFromCpaXml : IInnographyIdFromCpaXml
    {
        public string Resolve(string cpaXml)
        {
            if (string.IsNullOrWhiteSpace(cpaXml)) throw new ArgumentNullException(nameof(cpaXml));

            var caseDetails = CpaXmlHelper.Parse(cpaXml).FindFirstCaseDetail();

            if (string.IsNullOrWhiteSpace(caseDetails.SenderCaseIdentifier))
            {
                throw new InvalidOperationException("Innography ID not available");
            }

            return caseDetails.SenderCaseIdentifier;
        }
    }
}