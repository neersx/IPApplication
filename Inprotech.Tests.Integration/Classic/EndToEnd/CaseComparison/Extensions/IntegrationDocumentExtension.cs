using System;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Integration.Extensions;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions
{
    public static class IntegrationDocumentExtension
    {
        public static Document WithDefaults(this Document doc)
        {
            doc.DocumentObjectId = RandomString.Next(10);
            doc.FileWrapperDocumentCode = RandomString.Next(10);
            doc.DocumentCategory = RandomString.Next(10);
            doc.Reference = Guid.NewGuid();
            doc.CreatedOn = DateTime.Now;
            doc.UpdatedOn = DateTime.Now;
            return doc;
        }
    }
}