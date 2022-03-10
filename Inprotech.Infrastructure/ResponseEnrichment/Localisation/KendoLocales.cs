using System.IO;

namespace Inprotech.Infrastructure.ResponseEnrichment.Localisation
{
    public interface IKendoLocale
    {
        string Resolve(string culture);
    }

    public class KendoLocale : IKendoLocale
    {
        const string PathTemplate = "condor/kendo-intl/{0}";
        const string DefaultLocale = "en";
        const string BasePath = "client";
        readonly IFileHelpers _fileHelpers;

        public KendoLocale(IFileHelpers fileHelpers)
        {
            _fileHelpers = fileHelpers;
        }

        public string Resolve(string culture)
        {
            if (string.IsNullOrWhiteSpace(culture)) return DefaultLocale;
            var path = string.Format(PathTemplate, culture);
            if (_fileHelpers.DirectoryExists(Path.Combine(BasePath, path)))
                return culture;
            
            var fallback = culture.Split('-')[0];
            path = string.Format(PathTemplate, fallback);
            return _fileHelpers.DirectoryExists(Path.Combine(BasePath, path)) ? fallback : DefaultLocale;
        }
    }
}
