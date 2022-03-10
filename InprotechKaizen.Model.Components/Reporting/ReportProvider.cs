using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Integration.ReportingServices;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Reporting
{
    public interface IReportProvider
    {
        Task<ProviderInfo> GetDefaultProviderInfo();

        Task<ProviderInfo> GetReportProviderInfo();
    }

    public sealed class ReportProvider : IReportProvider
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCulture;
        readonly IReportingServicesSettingsResolver _settingsResolver;

        public ReportProvider(IDbContext dbContext, IPreferredCultureResolver preferredCulture, IReportingServicesSettingsResolver settingsResolver)
        {
            _dbContext = dbContext;
            _preferredCulture = preferredCulture;
            _settingsResolver = settingsResolver;
        }

        public async Task<ProviderInfo> GetDefaultProviderInfo()
        {
            return await GetProviderInfoByType(ReportProviderType.Default);
        }

        public async Task<ProviderInfo> GetReportProviderInfo()
        {
            var reportProvider = await _settingsResolver.Resolve();

            return !reportProvider.IsValid() ? null : await GetProviderInfoByType(ReportProviderType.MsReportingServices);
        }

        async Task<ProviderInfo> GetProviderInfoByType(ReportProviderType providerType)
        {
            if (providerType is ReportProviderType.Default or ReportProviderType.MsReportingServices)
            {
                var culture = _preferredCulture.Resolve();

                var allExportFormats = await GetExportFormats(culture).ToArrayAsync();

                var exportFormatByType =
                    (from a in allExportFormats
                     where providerType == ReportProviderType.Default && a.ReportToolKey == null ||
                           providerType == ReportProviderType.MsReportingServices && a.ReportToolKey is (int) ReportProviderType.MsReportingServices
                     select new ExportFormatData
                     {
                         ExportFormatKey = (ReportExportFormat) a.ExportFormatKey,
                         ExportFormatDescription = a.ExportFormatDescription,
                         IsDefault = a.ExportFormatKey == (int) ReportExportFormat.Pdf
                     }).ToArray();

                return new ProviderInfo
                {
                    Provider = providerType,
                    Name = providerType.ToString(),
                    ExportFormats = exportFormatByType,
                    DefaultExportFormat = GetDefaultExportFormat(exportFormatByType)
                };
            }

            return null;
        }

        static ReportExportFormat GetDefaultExportFormat(IEnumerable<ExportFormatData> formats)
        {
            var exportFormats = formats as ExportFormatData[] ?? formats.ToArray();
            var defaultExportFormat = exportFormats.FirstOrDefault(ef => ef.IsDefault);
            return defaultExportFormat?.ExportFormatKey ?? (exportFormats.First()?.ExportFormatKey ?? ReportExportFormat.Excel);
        }

        IQueryable<ExportFormatByReportType> GetExportFormats(string culture)
        {
            return (from p in _dbContext.Set<ReportToolExportFormat>()
                    join tc in _dbContext.Set<TableCode>() on p.ExportFormat equals tc.Id
                    where p.UsedByWorkbench
                    select new ExportFormatByReportType
                    {
                        ReportToolKey = p.ReportTool,
                        ExportFormatKey = p.ExportFormat,
                        ExportFormatDescription = tc.Name != null
                            ? DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture)
                            : null
                    }).OrderBy(_ => _.ExportFormatDescription);
        }
    }

    public enum ReportProviderType
    {
        Default = 0,
        MsReportingServices = 9402
    }

    public class ProviderInfo
    {
        public ReportProviderType Provider { get; set; }

        public string Name { get; set; }

        public ReportExportFormat DefaultExportFormat { get; set; }

        public IEnumerable<ExportFormatData> ExportFormats { get; set; }
    }

    public class ExportFormatByReportType
    {
        public int? ReportToolKey { get; set; }
        public int ExportFormatKey { get; set; }
        public string ExportFormatDescription { get; set; }
    }
}