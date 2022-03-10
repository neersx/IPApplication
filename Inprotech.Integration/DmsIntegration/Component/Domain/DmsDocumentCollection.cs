using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Inprotech.Integration.DmsIntegration.Component.Domain
{
    public class DmsDocumentCollection
    {
        public IEnumerable<DmsDocument> DmsDocuments { get; set; }
        public int TotalCount { get; set; }
    }
}
