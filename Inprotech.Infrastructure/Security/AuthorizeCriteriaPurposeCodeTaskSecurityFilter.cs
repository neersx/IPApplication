using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using Autofac.Integration.WebApi;
using InprotechKaizen.Model.Security;

namespace Inprotech.Infrastructure.Security
{
    class AuthorizeCriteriaPurposeCodeTaskSecurityFilter : IAutofacAuthorizationFilter
    {
        readonly IAuthorizeCriteriaPurposeCodeTaskSecurity _codeTaskSecurity;

        public AuthorizeCriteriaPurposeCodeTaskSecurityFilter(IAuthorizeCriteriaPurposeCodeTaskSecurity codeTaskSecurity)
        {
            _codeTaskSecurity = codeTaskSecurity;
        }
        public Task OnAuthorizationAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext == null)
                throw new ArgumentNullException(nameof(actionContext));

            var criteriaTaskSecurityAttribute = actionContext.ActionDescriptor.GetCustomAttributes<AuthorizeCriteriaPurposeCodeTaskSecurityAttribute>().SingleOrDefault();
            if (criteriaTaskSecurityAttribute == null)
                return Task.FromResult(0);

            var purposeCode = GetPurposeCode(actionContext, criteriaTaskSecurityAttribute);

            if (!_codeTaskSecurity.Authorize(purposeCode))
            {
                throw new HttpResponseException(actionContext.Request.CreateErrorResponse(HttpStatusCode.Forbidden,
                                                                                          ErrorTypeCode.PermissionDenied.ToString()));
            }

            return Task.FromResult(0);
        }

        static string GetPurposeCode(HttpActionContext actionContext, AuthorizeCriteriaPurposeCodeTaskSecurityAttribute criteriaTaskSecurityAttribute)
        {
            var purposeCode = string.Empty;

            var propertyNames = string.IsNullOrWhiteSpace(criteriaTaskSecurityAttribute.PropertyName)
                ? AuthorizeCriteriaPurposeCodeTaskSecurityAttribute.CommonPropertyNames
                : new[] { criteriaTaskSecurityAttribute.PropertyName };
            var queryString = actionContext.Request
                                           .GetQueryNameValuePairs()
                                           .ToDictionary(x => x.Key, x => x.Value);
            var propertyName = propertyNames.FirstOrDefault(_ => queryString.ContainsKey(_));
            if (propertyName != null)
            {
                purposeCode = queryString[propertyName];
            }

            return purposeCode;
        }
    }
}