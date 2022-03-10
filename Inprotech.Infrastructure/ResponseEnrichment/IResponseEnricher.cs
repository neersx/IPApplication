using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.ResponseEnrichment
{
    public interface IResponseEnricher
    {
        Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment);
    }
}
