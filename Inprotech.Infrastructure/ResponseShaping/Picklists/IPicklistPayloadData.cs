using System.Collections.Generic;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.ResponseShaping.Picklists
{
    public interface IPicklistPayloadData
    {
        void Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment);
    }
}
