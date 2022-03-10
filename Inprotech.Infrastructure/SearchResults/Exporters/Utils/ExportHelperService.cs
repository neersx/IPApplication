using Inprotech.Infrastructure.SearchResults.Exporters.Config;

namespace Inprotech.Infrastructure.SearchResults.Exporters.Utils
{
    public interface IExportHelperService
    {
        string Translate(string original);
        
        ExportConfig LayoutSettings { get; }
    }
}