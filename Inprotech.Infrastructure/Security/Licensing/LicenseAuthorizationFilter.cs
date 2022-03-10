using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.Security.Licensing
{
    public class LicenseAuthorisationFilter : IAutofacAuthorizationFilter
    {
        readonly ILicenseAuthorization _licenseAuthorization;

        public LicenseAuthorisationFilter(ILicenseAuthorization licenseAuthorization)
        {
            if (licenseAuthorization == null) throw new ArgumentNullException(nameof(licenseAuthorization));

            _licenseAuthorization = licenseAuthorization;
        }

        public Task OnAuthorizationAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext == null) throw new ArgumentNullException(nameof(actionContext));

            if (!_licenseAuthorization.Authorize(
                                                 actionContext.ActionDescriptor.ControllerDescriptor
                                                              .GetCustomAttributes<RequiresLicenseAttribute>()
                                                              .ToArray()))
            {
                throw new HttpResponseException(actionContext.Request.CreateErrorResponse(HttpStatusCode.Forbidden,
                                                                                          ErrorTypeCode.PermissionDenied.ToString()));
            }

            return Task.FromResult(0);
        }
    }
}