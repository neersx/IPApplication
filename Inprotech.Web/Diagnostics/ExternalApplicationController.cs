using System;
using System.Linq;
using System.Text;
using System.Threading;
using System.Web.Http;
using System.Web.Http.Controllers;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security.ExternalApplications;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Diagnostics
{
    internal static class ExternalApplicationDiagnosticHelpers
    {
        public static dynamic BuildResult(string action, IExternalApplicationContext extAppContext, ISecurityContext securityContext,
            HttpRequestContext requestContext)
        {
            return new
            {
                Action = action,
                ApplicationName = extAppContext.ExternalApplicationName,
                Username = securityContext.User != null ? securityContext.User.UserName : "<no security context>",
                RequestContextIsAuthenticated = requestContext.Principal != null ? requestContext.Principal.Identity.IsAuthenticated.ToString() : "<no user>",
                RequestContextName = requestContext.Principal != null ? requestContext.Principal.Identity.Name : "<no user>",
                RequestContextAuthType = requestContext.Principal != null ? requestContext.Principal.Identity.AuthenticationType : "<no user>",
                ThreadIsAuthenticated = Thread.CurrentPrincipal != null ? Thread.CurrentPrincipal.Identity.IsAuthenticated.ToString() : "<unknown>",
                ThreadName = Thread.CurrentPrincipal != null ? Thread.CurrentPrincipal.Identity.Name : "<unknown>",
                ThreadAuthType = Thread.CurrentPrincipal != null ? Thread.CurrentPrincipal.Identity.AuthenticationType : "<unknown>"
            };
        }

        public static string GetPropertyInfo(object obj)
        {
            var sb = new StringBuilder();
            foreach (var property in obj.GetType().GetProperties().Where(property => property.GetIndexParameters().Length <= 0))
            {
                sb.Append(property.Name);
                sb.Append(": ");
                sb.Append(property.GetValue(obj, null));

                sb.Append(Environment.NewLine);
            }

            return sb.ToString();
        }
    }

    [RequiresApiKey(ExternalApplicationName.Inprotech)]
    [RoutePrefix("api/diagnostics/externalapplication")]
    public class ExternalApplicationController : ApiController
    {
        private readonly ILogger<ExternalApplicationController> _logger;
        private readonly ISecurityContext _securityContext;
        private readonly IExternalApplicationContext _externalApplicationContext;

        public ExternalApplicationController(ILogger<ExternalApplicationController> logger, ISecurityContext securityContext, IExternalApplicationContext externalApplicationContext)
        {
            _logger = logger;
            _securityContext = securityContext;
            _externalApplicationContext = externalApplicationContext;
        }

        [Route("usernotrequired")]
        [NoEnrichment]
        public dynamic Get()
        {
            var result = ExternalApplicationDiagnosticHelpers.BuildResult("Get - user not required", _externalApplicationContext, _securityContext,
                ControllerContext.RequestContext);
            _logger.Information((string)ExternalApplicationDiagnosticHelpers.GetPropertyInfo(result));
            return result;
        }
    }

    [RequiresApiKey(ExternalApplicationName.Inprotech, true)]
    [RoutePrefix("api/diagnostics/externalapplication")]
    public class ExternalApplicationWithUserController : ApiController
    {
        private readonly ILogger<ExternalApplicationWithUserController> _logger;
        private readonly ISecurityContext _securityContext;
        private readonly IExternalApplicationContext _externalApplicationContext;

        public ExternalApplicationWithUserController(ILogger<ExternalApplicationWithUserController> logger, ISecurityContext securityContext, IExternalApplicationContext externalApplicationContext)
        {
            _logger = logger;
            _securityContext = securityContext;
            _externalApplicationContext = externalApplicationContext;
        }

        [Route("userrequired")]
        [NoEnrichment]
        public dynamic Get()
        {
            var result = ExternalApplicationDiagnosticHelpers.BuildResult("Get - user required", _externalApplicationContext, _securityContext,
                ControllerContext.RequestContext);
            _logger.Information((string)ExternalApplicationDiagnosticHelpers.GetPropertyInfo(result));
            return result;
        }
        
    }
}
