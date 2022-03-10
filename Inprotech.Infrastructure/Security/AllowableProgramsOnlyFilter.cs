using System;
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.Security
{
    public class AllowableProgramsOnlyFilter : IAutofacActionFilter
    {
        readonly IAllowableProgramsResolver _allowableProgramsResolver;
        public AllowableProgramsOnlyFilter(IAllowableProgramsResolver allowableProgramsResolver)
        {
            _allowableProgramsResolver = allowableProgramsResolver;
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext actionExecutedContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public async Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext == null) throw new ArgumentNullException(nameof(actionContext));

            if (TryExtractAuthorizationParameters(actionContext, out string programId))
            {
                if (!(await _allowableProgramsResolver.Resolve()).Contains(programId))
                    throw new HttpResponseException(HttpStatusCode.Forbidden);
            }
        }

        static bool TryExtractAuthorizationParameters(HttpActionContext actionContext, out string programId)
        {
            programId = string.Empty;

            var allowableProgramsOnlyAttribute = actionContext.ActionDescriptor.GetCustomAttributes<AllowableProgramsOnlyAttribute>().SingleOrDefault();
            if (allowableProgramsOnlyAttribute != null)
            {
                var propertyNames = string.IsNullOrWhiteSpace(allowableProgramsOnlyAttribute.PropertyName)
                    ? AllowableProgramsOnlyAttribute._commonPropertyNames
                    : new[] { allowableProgramsOnlyAttribute.PropertyName };

                var propertyName = propertyNames.FirstOrDefault(_ => actionContext.ActionArguments.ContainsKey(_));
                if (propertyName != null)
                {
                    programId = actionContext.ActionArguments[propertyName] as string;
                }
            }
            var extracted = !string.IsNullOrEmpty(programId);
            return extracted;
        }
    }
}