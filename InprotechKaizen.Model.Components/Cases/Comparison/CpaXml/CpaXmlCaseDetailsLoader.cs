using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml
{
    public interface ICpaXmlCaseDetailsLoader
    {
        (CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messages) Load(string xml);
    }

    public class CpaXmlCaseDetailsLoader : ICpaXmlCaseDetailsLoader
    {
        public (CaseDetails caseDetails, IEnumerable<TransactionMessageDetails> messages) Load(string xml)
        {
            if (string.IsNullOrWhiteSpace(xml)) throw new ArgumentNullException(nameof(xml));

            var transaction = CpaXmlHelper.Parse(xml);
            var body = transaction.TransactionBody;

            var caseDetails = body
                .Select(tb => tb.TransactionContentDetails)
                .Select(tcd => tcd.TransactionData)
                .Select(td => td.CaseDetails)
                .FirstOrDefault();

            var messages = body.SelectMany(tb => tb.TransactionMessageDetails);

            return (caseDetails, messages);
        }
    }
}