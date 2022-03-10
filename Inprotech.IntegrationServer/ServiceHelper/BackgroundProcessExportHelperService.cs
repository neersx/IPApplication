using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;

namespace Inprotech.IntegrationServer.ServiceHelper
{
    public class BackgroundProcessExportHelperService : IExportHelperService
    {
        readonly ExportConfig _defaultSettings = new ExportConfig();

        public string Translate(string original)
        {
            return original;
        }

        public ExportConfig LayoutSettings => _defaultSettings;
    }
}
