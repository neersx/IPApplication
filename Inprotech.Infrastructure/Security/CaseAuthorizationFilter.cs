using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.Infrastructure.Security
{
    public class CaseAuthorizationFilter : IAutofacActionFilter
    {
        readonly ICurrentIdentity _securityContext;
        readonly ICaseAuthorization _caseAuthorization;
        readonly IAuthorizationResultCache _authorizationResultCache;

        public CaseAuthorizationFilter(ICurrentIdentity securityContext, ICaseAuthorization caseAuthorization, IAuthorizationResultCache authorizationResultCache)
        {
            _securityContext = securityContext;
            _caseAuthorization = caseAuthorization;
            _authorizationResultCache = authorizationResultCache;
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext actionExecutedContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public async Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext == null) throw new ArgumentNullException(nameof(actionContext));

            if (TryExtractAuthorizationParameters(actionContext, out (AccessPermissionLevel MinumumLevel, int caseId) parameters))
            {
                var caseId = parameters.caseId;
                var identityId = _securityContext.IdentityId;
                var requestedAccessLevel = parameters.MinumumLevel;

                if (!_authorizationResultCache.TryGetCaseAuthorizationResult(identityId, caseId, requestedAccessLevel, out var result))
                {
                    result = await _caseAuthorization.Authorize(caseId, requestedAccessLevel);
                    _authorizationResultCache.TryAddCaseAuthorizationResult(identityId, caseId, requestedAccessLevel, result);
                }
                
                if (!result.Exists)
                {
                    actionContext.Response = actionContext.Request.CreateErrorResponse(HttpStatusCode.NotFound, "Case Not Found");
                    return;
                }

                if (result.IsUnauthorized)
                {
                    throw new DataSecurityException(result.ReasonCode.CamelCaseToUnderscore());
                }
            }
        }

        static bool TryExtractAuthorizationParameters(HttpActionContext actionContext, out (AccessPermissionLevel minimumPermissionLevel, int caseId) parameters)
        {
            object returnCaseIdObject = null;
            var returnCaseId = int.MinValue;
            var extracted = false;
            var returnMinimumAccessLevel = AccessPermissionLevel.Select;

            var requireCaseAccess = actionContext.ActionDescriptor.GetCustomAttributes<RequiresCaseAuthorizationAttribute>().SingleOrDefault();
            if (requireCaseAccess != null)
            {
                returnMinimumAccessLevel = requireCaseAccess.MinimumAccessPermission;

                var propertyNames = string.IsNullOrWhiteSpace(requireCaseAccess.PropertyName)
                    ? RequiresCaseAuthorizationAttribute.CommonPropertyNames
                    : new[] {requireCaseAccess.PropertyName};

                if (!string.IsNullOrWhiteSpace(requireCaseAccess.PropertyPath) && requireCaseAccess.PropertyPath.Contains("."))
                {
                    var propertyQueue = new Queue<string>(requireCaseAccess.PropertyPath.Split('.'));
                    var topLevelArg = propertyQueue.Dequeue();
                    var currentObject = actionContext.ActionArguments[topLevelArg];
                    while (propertyQueue.Any() && currentObject != null)
                    {
                        var propertyName = propertyQueue.Dequeue();
                        var property = currentObject.GetType().GetProperty(propertyName);
                        if (property == null) throw new InvalidOperationException("Unable to align propertyPath with api parameter payload.");
                        currentObject = property.GetValue(currentObject);
                    }

                    if (currentObject != null)
                    {
                        returnCaseIdObject = currentObject;
                    }
                }
                else
                {
                    var propertyName = propertyNames.FirstOrDefault(_ => actionContext.ActionArguments.ContainsKey(_));
                    if (propertyName != null)
                    {
                        returnCaseIdObject = actionContext.ActionArguments[propertyName];
                    }
                }

                if (returnCaseIdObject != null)
                {
                    var val = returnCaseIdObject as int? ?? (int.TryParse(returnCaseIdObject as string, out int v) ? (int?) v : null);
                    if (val.HasValue)
                    {
                        extracted = true;
                        returnCaseId = val.Value;
                    }
                }
            }

            parameters = (returnMinimumAccessLevel, returnCaseId);
            return extracted;
        }
    }
}