using System.IO;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Newtonsoft.Json;

namespace Inprotech.Web.Exporters
{
    public interface IExportConfigProvider
    {
        ExportConfig GetConfig();
    }

    public class ExportConfigProvider : IExportConfigProvider
    {
        const string InprotechExportConfig = @"Inprotech.Export.json";

        public ExportConfig GetConfig()
        {
            if (!File.Exists(InprotechExportConfig))
                return new ExportConfig();

            var json = File.ReadAllText("Inprotech.Export.json");
            return JsonConvert.DeserializeObject<ExportConfig>(json);
        }
    }
}
