using System;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.Policy
{
    public class AuditTrailFilter : IAutofacActionFilter
    {
        readonly IAuditTrail _auditTrail;
        readonly IComponentResolver _componentResolver;

        public AuditTrailFilter(IAuditTrail auditTrail,
            IComponentResolver componentResolver)
        {
            _auditTrail = auditTrail ?? throw new ArgumentNullException(nameof(auditTrail));
            _componentResolver = componentResolver ?? throw new ArgumentNullException(nameof(componentResolver));
        }

        public Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            var p = actionContext.Request.GetRequestContext().Principal;

            var appLink = p as ExternalApplicationPrincipal;
            if (appLink != null && !appLink.HasUserContext)
            {
                return Task.FromResult(0);
            }

            if (p?.Identity == null || !p.Identity.IsAuthenticated)
            {
                return Task.FromResult(0);
            }

            var component = Resolve(actionContext);

            _auditTrail.Start(_componentResolver.Resolve(component));

            return Task.FromResult(0);
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext actionContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        string Resolve(HttpActionContext actionContext)
        {
            var operationApplicable = actionContext.Request.Method.Equals(HttpMethod.Post)
                || actionContext.Request.Method.Equals(HttpMethod.Put)
                || actionContext.Request.Method.Equals(HttpMethod.Delete);

            if (!operationApplicable) return null;

            var appliesToComponent = actionContext.ActionDescriptor
                                                  .GetCustomAttributes<AppliesToComponentAttribute>()
                                                  .SingleOrDefault();

            return appliesToComponent?.ComponentName;
        }
    }
}