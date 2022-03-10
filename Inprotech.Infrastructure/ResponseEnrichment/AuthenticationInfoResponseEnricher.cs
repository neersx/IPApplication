using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Infrastructure.ResponseEnrichment
{
    public class AuthenticationInfoResponseEnricher : IResponseEnricher
    {
        readonly IAuthSettings _authSettings;

        public AuthenticationInfoResponseEnricher(IAuthSettings authSettings)
        {
            _authSettings = authSettings;
        }
        public Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            if (actionExecutedContext == null) throw new ArgumentNullException("actionExecutedContext");
            if (enrichment == null) throw new ArgumentNullException("enrichment");

            enrichment.Add("isWindowsAuthOnly", _authSettings.WindowsEnabled && !(_authSettings.FormsEnabled || _authSettings.SsoEnabled));

            return Task.FromResult(0);
        }
    }
}
