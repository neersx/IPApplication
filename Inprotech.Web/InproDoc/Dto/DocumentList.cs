using System.Collections.Generic;

namespace Inprotech.Web.InproDoc.Dto
{
    public class DocumentList
    {
        public string NetworkTemplatesPath { get; set; }
        public string LocalTemplatesPath { get; set; }
        public IEnumerable<Document> Documents { get; set; }
    }
}