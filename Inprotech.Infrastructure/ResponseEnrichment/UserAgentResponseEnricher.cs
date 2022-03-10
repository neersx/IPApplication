using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.ResponseEnrichment
{
    class UserAgentResponseEnricher : IResponseEnricher
    {
        public Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            enrichment.Add("userAgent", new
            {
                Languages = actionExecutedContext.Request.Headers.AcceptLanguage.OrderByDescending(a => a.Quality ?? 1).Select(a => a.Value).ToArray()
            });
            
            return Task.FromResult(0);
        }
    }
}
