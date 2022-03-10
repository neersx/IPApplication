using System.Collections.Generic;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.ResponseShaping.Picklists
{
    public class DuplicateFromServer : IPicklistPayloadData
    {
        public void Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            var d = actionExecutedContext.PicklistPayloadAttribute();
            if (d.DuplicateFromServer.GetValueOrDefault())
                enrichment.Add("DuplicateFromServer", true);
        }
    }
}