using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Instrumentation;

namespace Inprotech.Infrastructure.ResponseEnrichment.Instrumentation
{
    public class InstrumentationDetailsEnricher : IResponseEnricher
    {
        readonly IApplicationInsights _applicationInsights;

        public InstrumentationDetailsEnricher(IApplicationInsights applicationInsights)
        {
            _applicationInsights = applicationInsights;
        }

        public Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            if (actionExecutedContext == null) throw new ArgumentNullException(nameof(actionExecutedContext));
            if (enrichment == null) throw new ArgumentNullException(nameof(enrichment));

            var settings = _applicationInsights.InstrumentationSettings;
            enrichment.Add("instrumentationKey", settings?.Key);
            enrichment.Add(nameof(_applicationInsights.InstrumentationSettings.ExceptionTracking), settings?.ExceptionTracking);
            enrichment.Add(nameof(_applicationInsights.InstrumentationSettings.SessionTracking), settings?.SessionTracking);
            enrichment.Add(nameof(_applicationInsights.InstrumentationSettings.PerformanceTracking), settings?.PerformanceTracking);

            return Task.FromResult(0);
        }
    }
}