namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public class ExportResult
    {
        public string FileName { get; set; }
        public byte[] Content { get; set; }
        public string ContentType { get; set; }
        public long ContentLength { get; set; }
    }
}
