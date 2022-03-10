using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Documents
{
    [NotMapped]
    public class ComparisonDocument : Document
    {
        public Guid CorrelationId { get; private set; }

        public ComparisonDocument()
        {
            CorrelationId = Guid.NewGuid();
        }

        public override string CorrelationRef()
        {
            return CorrelationId.ToString();
        }
    }
}
