using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Policy;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Search.Export
{
    public class ExportSettingsLoader : IExportSettings
    {
        readonly ISecurityContext _securityContext;
        readonly ISiteDateFormat _siteDateFormat;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControlReader;
        readonly IExportHelperService _exportHelperService;
        readonly IStaticTranslator _staticTranslator;
        const int MaxRowsForExcel = 65536;
        readonly string reportTitlePrefix = "searchResults.title.";
        
        public ExportSettingsLoader(ISecurityContext securityContext, ISiteDateFormat siteDateFormat,
                                    IPreferredCultureResolver preferredCultureResolver,
                                    ISiteControlReader siteControlReader,
                                    IExportHelperService exportHelperService,
                                    IStaticTranslator staticTranslator)
        {
            _securityContext = securityContext;
            _siteDateFormat = siteDateFormat;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControlReader = siteControlReader;
            _exportHelperService = exportHelperService;
            _staticTranslator = staticTranslator;
        }

        public SearchResultsSettings Load(string searchName, QueryContext queryContext)
        {
            var loggedInUser = _securityContext.User.Name;
            var culture = _preferredCultureResolver.Resolve();

            var settings = new SearchResultsSettings
            {
                ApplicationName = KnownGlobalSettings.ApplicationName,
                Author = FormattedName.For(loggedInUser.LastName, loggedInUser.FirstName),
                LayoutSettings = _exportHelperService.LayoutSettings,
                Culture = new CultureInfo(culture),
                DateFormat = _siteDateFormat.Resolve(culture),
                Warnings = Warnings(_staticTranslator, _preferredCultureResolver),
                FontSettings = new Dictionary<ReportExportFormat, FontSetting>
                {
                    {
                        ReportExportFormat.Excel, new FontSetting
                        {
                            FontSize = 8,
                            FontFamily = "Arial"
                        }
                    }
                },
                MaxColumnsForExport = 255,
                ReportTitle = !string.IsNullOrEmpty(searchName) ? searchName
                    : _staticTranslator.Translate(reportTitlePrefix + queryContext, _preferredCultureResolver.ResolveAll().ToArray())
            };
            
            settings.LoadImages();
            settings.ReportFileName = settings.ReportTitle.Replace(" ", string.Empty);
            settings.TimeFormat = settings.Culture.DateTimeFormat.GetAllDateTimePatterns('t')[0];
            return settings;
        }

        Dictionary<string, string> Warnings(IStaticTranslator translator, IPreferredCultureResolver preferredCultureResolver)
        {
            var acceptableCultures = preferredCultureResolver.ResolveAll().ToArray();
            var warnings = new Dictionary<string, string>
            {
                {
                    "RowsTruncatedWarning",
                    translator.Translate("searchResults.warning.truncatedRows", acceptableCultures)
                },
                {
                    "ColumnsTruncatedWarning",
                    translator.Translate("searchResults.warning.truncatedColumns", acceptableCultures)
                }
            };
            return warnings;
        }

        public int? GetExportLimitorDefault(ReportExportFormat reportExportFormat)
        {
            var exportLimit = _siteControlReader.Read<int?>(SiteControls.ExportLimit);

            if (reportExportFormat != ReportExportFormat.Excel) return exportLimit;

            if (exportLimit.HasValue && exportLimit > MaxRowsForExcel || !exportLimit.HasValue)
                exportLimit = MaxRowsForExcel;

            return exportLimit;
        }
    }
}
