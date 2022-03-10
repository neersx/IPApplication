using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Security.Access
{
    public class ProgramAccessEnricher : IResponseEnricher
    {
        IAllowableProgramsResolver _allowablePrograms;

        public ProgramAccessEnricher(IAllowableProgramsResolver allowablePrograms)
        {
            _allowablePrograms = allowablePrograms;
        }

        public async Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            enrichment.Add("Programs", await _allowablePrograms.Resolve());
        }
    }
}
