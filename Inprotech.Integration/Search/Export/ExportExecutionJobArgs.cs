using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure.SearchResults.Exporters;

namespace Inprotech.Integration.Search.Export
{
    public class ExportExecutionJobArgs : Message
    {
        public ExportRequest ExportRequest {get; set; }
        public SearchResultsSettings Settings { get; set; }
    }
}
