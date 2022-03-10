using System;
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.Security
{
    public class TaskAuthorisationFilter : IAutofacAuthorizationFilter
    {
        readonly ITaskAuthorisation _taskAuthorisation;

        public TaskAuthorisationFilter(ITaskAuthorisation taskAuthorisation)
        {
            _taskAuthorisation = taskAuthorisation ?? throw new ArgumentNullException(nameof(taskAuthorisation));
        }

        public Task OnAuthorizationAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext == null) throw new ArgumentNullException(nameof(actionContext));

            if (!_taskAuthorisation.Authorize(
                                              actionContext.ActionDescriptor
                                                           .GetCustomAttributes<RequiresAccessToAttribute>()
                                                           .ToArray(),
                                              actionContext.ActionDescriptor.ControllerDescriptor
                                                           .GetCustomAttributes<RequiresAccessToAttribute>()
                                                           .ToArray()))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            return Task.FromResult(0);
        }
    }
}