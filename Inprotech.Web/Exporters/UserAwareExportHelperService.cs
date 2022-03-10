using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;

namespace Inprotech.Web.Exporters
{
    public class UserAwareExportHelperService : IExportHelperService
    {
        readonly IStaticTranslator _staticTranslator;

        readonly string[] _userCultures;

        public UserAwareExportHelperService(IStaticTranslator staticTranslator, IPreferredCultureResolver preferredCultureResolver, IExportConfigProvider exportConfigProvider)
        {
            _staticTranslator = staticTranslator;
            _userCultures = preferredCultureResolver.ResolveAll().ToArray();
            LayoutSettings = exportConfigProvider.GetConfig();
        }

        public string Translate(string original)
        {
            return _staticTranslator.Translate(original, _userCultures);
        }

        public ExportConfig LayoutSettings { get; }
    }
}
