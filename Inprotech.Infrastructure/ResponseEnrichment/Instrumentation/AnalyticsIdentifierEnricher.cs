using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Instrumentation;

namespace Inprotech.Infrastructure.ResponseEnrichment.Instrumentation
{
    class AnalyticsIdentifierEnricher : IResponseEnricher
    {
        readonly AnalyticsRuntimeSettings _analyticsRuntimeSettings;

        public AnalyticsIdentifierEnricher(AnalyticsRuntimeSettings analyticsRuntimeSettings)
        {
            _analyticsRuntimeSettings = analyticsRuntimeSettings;
        }

        public Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            enrichment.Add("gaSettings", new
            {
                key = _analyticsRuntimeSettings.IdentifierKey
            });

            return Task.FromResult(0);
        }
    }
}