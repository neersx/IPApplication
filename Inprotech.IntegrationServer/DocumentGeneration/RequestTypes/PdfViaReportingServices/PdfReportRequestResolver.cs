using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Integration.Reports;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.PdfViaReportingServices
{
    public interface IPdfReportRequestResolver
    {
        Task<ReportDefinition> Resolve(DocGenRequest docGenRequest);
    }

    public class PdfReportRequestResolver : IPdfReportRequestResolver
    {
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly IBackgroundProcessLogger<PdfReportRequestResolver> _logger;

        public PdfReportRequestResolver(IDbContext dbContext, IBackgroundProcessLogger<PdfReportRequestResolver> logger, IDocItemRunner docItemRunner)
        {
            _dbContext = dbContext;
            _logger = logger;
            _docItemRunner = docItemRunner;
        }
        
        public async Task<ReportDefinition> Resolve(DocGenRequest docGenRequest)
        {
            if (docGenRequest == null) throw new ArgumentNullException(nameof(docGenRequest));

            _logger.SetContext(docGenRequest.Context);
            _logger.Trace($"Processing DocGenRequest {docGenRequest.Id} from PdfViaReportingServices");

            var result = new ReportDefinition
            {
                ReportPath = docGenRequest.TemplateName,
                ReportExportFormat = ReportExportFormat.Pdf,
                Parameters = new Dictionary<string, string>()
            };

            var configuredParameters = await (from r in _dbContext.Set<ReportParameter>()
                                              join i in _dbContext.Set<DocItem>() on r.ItemId equals i.Id into i1
                                              from i in i1
                                              where r.LetterId == docGenRequest.LetterId
                                              select new
                                              {
                                                  r.Name,
                                                  r.ItemId,
                                                  ItemName = i.Name,
                                                  i.EntryPointUsage
                                              })
                .ToDictionaryAsync(k => k.Name, v => v);

            var invalidDataItems = configuredParameters.Where(_ => _.Value.EntryPointUsage != KnownEntryPoints.ActivityId)
                                                       .Select(_ => _.Value.ItemName)
                                                       .Distinct()
                                                       .ToArray();

            if (invalidDataItems.Any())
            {
                _logger.Warning($"Unexpected Entry Point Value detected when generating ({docGenRequest.LetterName} (PDF via Reporting Services), id={docGenRequest.Id}): {string.Join(", ", invalidDataItems)}. They must be 20 (ActivityRequest.Id).");
            }

            foreach (var cp in configuredParameters)
            {
                var itemParameters = DefaultDocItemParameters.ForDocItemSqlQueries(docGenRequest.Id.ToString());
                var p = _docItemRunner.Run(cp.Value.ItemName, itemParameters).ScalarValueOrDefault<object>();

                result.Parameters.Add(cp.Key, p?.ToString());
            }

            _logger.Trace($"Processed DocGenRequest {docGenRequest.Id} from PdfViaReportingServices", result);
            return result;
        }
    }
}