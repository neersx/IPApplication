namespace Inprotech.Integration.DmsIntegration.Component.Domain
{
    public class DownloadDocumentResponse
    {
        public string FileName { get; set; }
        public string ApplicationName { get; set; }
        public byte[] DocumentData { get; set; }
        public long? ContentLength => DocumentData?.LongLength;
        public string ContentType { get; set; }
    }
}