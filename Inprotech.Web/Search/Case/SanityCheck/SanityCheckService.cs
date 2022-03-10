using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.DataValidation;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Case.SanityCheck
{
    public interface ISanityCheckService
    {
        Task<ExportResult> Export(SanityResultRequestParams searchRequestParams);
        Task<SanityCheckResults[]> GetSanityCheckResults(SanityResultRequestParams searchRequestParams);
    }

    public class SanityCheckService : ISanityCheckService
    {
        readonly IDbContext _dbContext;
        readonly IExportSettings _exportSettings;
        readonly IFormattedNameAddressTelecom _formattedNameAddressTelecom;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISearchResultsExport _searchResultsExport;
        readonly IStaticTranslator _staticTranslator;

        public SanityCheckService(IExportSettings exportSettings, ISearchResultsExport searchResultsExport, IDbContext dbContext, IFormattedNameAddressTelecom formattedNameAddressTelecom, IStaticTranslator staticTranslator, IPreferredCultureResolver preferredCultureResolver)
        {
            _exportSettings = exportSettings;
            _searchResultsExport = searchResultsExport;
            _dbContext = dbContext;
            _formattedNameAddressTelecom = formattedNameAddressTelecom;
            _staticTranslator = staticTranslator;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task<SanityCheckResults[]> GetSanityCheckResults(SanityResultRequestParams searchRequestParams)
        {
            if (searchRequestParams == null) throw new ArgumentNullException(nameof(SanityResultRequestParams));

            var results = (from scr in _dbContext.Set<SanityCheckResult>().Where(_ => _.ProcessId == searchRequestParams.ProcessId)
                           join c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>() on scr.CaseId equals c.Id
                           join cn in _dbContext.Set<CaseName>().Where(_ => _.NameTypeId == KnownNameTypes.StaffMember) on c.Id equals cn.CaseId into emp
                           from cn in emp.DefaultIfEmpty()
                           join cns in _dbContext.Set<CaseName>().Where(_ => _.NameTypeId == KnownNameTypes.Signatory) on c.Id equals cns.CaseId into sig
                           from cns in sig.DefaultIfEmpty()
                           join ofr in _dbContext.Set<Office>() on c.OfficeId equals ofr.Id into offices
                           from office in offices.DefaultIfEmpty()
                           select new SanityCheckResults
                           {
                               Staff = cn != null ? cn.NameId : (int?) null,
                               Signatory = cns != null ? cns.NameId : (int?) null,
                               ProcessKey = scr.ProcessId,
                               CaseKey = scr.CaseId,
                               CaseReference = c.Irn,
                               ByPassError = !scr.IsWarning && scr.CanOverride,
                               Error = !scr.IsWarning && !scr.CanOverride,
                               Information = scr.IsWarning,
                               DisplayMessage = scr.DisplayMessage,
                               OfficeId = c.OfficeId,
                               CaseOffice = c.OfficeId != null ? office.Name : string.Empty
                           }).Distinct().ToArray();

            if (!results.Any()) return results;

            var nameIds = new List<int>();
            nameIds.AddRange(from r in results where r.Staff != null select (int) r.Staff);
            nameIds.AddRange(from r in results where r.Signatory != null select (int) r.Signatory);

            var formattedNames = await _formattedNameAddressTelecom.GetFormatted(nameIds.ToArray(), NameStyles.FirstNameThenFamilyName);
            foreach (var r in results)
            {
                if (r.Staff.HasValue) r.StaffName = formattedNames?.Get(r.Staff.Value).Name;
                if (r.Signatory.HasValue) r.SignatoryName = formattedNames?.Get(r.Signatory.Value).Name;
            }

            return results;
        }

        public async Task<ExportResult> Export(SanityResultRequestParams searchRequestParams)
        {
            if (searchRequestParams?.ExportFormat == null) throw new ArgumentNullException(nameof(SanityResultRequestParams));

            var maxRowsToExport = _exportSettings.GetExportLimitorDefault(searchRequestParams.ExportFormat.Value);

            var exportData = await GetSanityCheckResults(searchRequestParams);

            var culture = _preferredCultureResolver.ResolveAll().ToArray();

            var columns = new List<Infrastructure.SearchResults.Exporters.Column>
            {
                new Infrastructure.SearchResults.Exporters.Column {Name = "Status", Title = _staticTranslator.TranslateWithDefault("sanityCheck.status", culture), Format = "String"},
                new Infrastructure.SearchResults.Exporters.Column {Name = "CaseReference", Title = _staticTranslator.TranslateWithDefault("sanityCheck.caseReference", culture), Format = "String"},
                new Infrastructure.SearchResults.Exporters.Column {Name = "CaseOffice", Title = _staticTranslator.TranslateWithDefault("sanityCheck.caseOffice", culture), Format = "String"},
                new Infrastructure.SearchResults.Exporters.Column {Name = "StaffName", Title = _staticTranslator.TranslateWithDefault("sanityCheck.staff", culture), Format = "String"},
                new Infrastructure.SearchResults.Exporters.Column {Name = "SignatoryName", Title = _staticTranslator.TranslateWithDefault("sanityCheck.signatory", culture), Format = "String"},
                new Infrastructure.SearchResults.Exporters.Column {Name = "DisplayMessage", Title = _staticTranslator.TranslateWithDefault("sanityCheck.displayMessage", culture), Format = "String"}
            };

            var rows = new List<Dictionary<string, object>>();

            foreach (var item in exportData)
            {
                var row = new Dictionary<string, object>(StringComparer.InvariantCultureIgnoreCase);

                foreach (var col in columns)
                {
                    switch (col.Name)
                    {
                        case "Status":
                            row[col.Name] = item.Status;
                            break;
                        case "CaseReference":
                            row[col.Name] = item.CaseReference;
                            break;
                        case "CaseOffice":
                            row[col.Name] = item.CaseOffice;
                            break;
                        case "StaffName":
                            row[col.Name] = item.StaffName;
                            break;
                        case "SignatoryName":
                            row[col.Name] = item.SignatoryName;
                            break;
                        case "DisplayMessage":
                            row[col.Name] = item.DisplayMessage;
                            break;
                    }
                }

                rows.Add(row);
            }

            var exportRequest = new ExportRequest
            {
                ExportFormat = searchRequestParams.ExportFormat.Value,
                Columns = columns,
                Rows = rows
            };

            var settings = _exportSettings.Load(_staticTranslator.TranslateWithDefault("sanityCheck.multipleResults", culture),
                                                QueryContext.CaseSearch);
            settings.ExportLimitedToNbRecords = exportData.Length <= maxRowsToExport
                ? null
                : maxRowsToExport;

            return await _searchResultsExport.Export(exportRequest, settings);
        }
    }
}