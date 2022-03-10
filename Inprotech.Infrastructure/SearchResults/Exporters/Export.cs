using System.IO;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    internal abstract class Export
    {
        public SearchResultsSettings Settings { get; }
        
        public SearchResults ExportData { get; }

        public IImageSettings ImageSettings { get; set; }

        public IUserColumnUrlResolver UserColumnUrlResolver { get; set; }

        public abstract string ContentType { get; }

        public abstract string FileNameExtension { get; }

        public abstract OpenType OpenType { get; }

        public abstract void Execute(Stream stream);

        protected Export(SearchResultsSettings settings, SearchResults exportData, IImageSettings imageSettings, IUserColumnUrlResolver userColumnUrlResolver)
        {
            Settings = settings;
            ExportData = exportData;
            ImageSettings = imageSettings;
            UserColumnUrlResolver = userColumnUrlResolver;
        }
    }

    public enum OpenType
    {
        Inline,
        Attachment
    }
}
