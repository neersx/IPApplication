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
    public class NameAuthorizationFilter : IAutofacActionFilter
    {
        readonly ICurrentIdentity _securityContext;
        readonly INameAuthorization _nameAuthorization;
        readonly IAuthorizationResultCache _authorizationResultCache;

        public NameAuthorizationFilter(ICurrentIdentity securityContext, INameAuthorization nameAuthorization, IAuthorizationResultCache authorizationResultCache)
        {
            _securityContext = securityContext;
            _nameAuthorization = nameAuthorization;
            _authorizationResultCache = authorizationResultCache;
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext actionExecutedContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public async Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext == null) throw new ArgumentNullException(nameof(actionContext));

            if (TryExtractAuthorizationParameters(actionContext, out (AccessPermissionLevel MinumumLevel, int nameId) parameters))
            {
                var nameId = parameters.nameId;
                var identityId = _securityContext.IdentityId;
                var requestedAccessLevel = parameters.MinumumLevel;

                if (!_authorizationResultCache.TryGetNameAuthorizationResult(identityId, nameId, requestedAccessLevel, out var result))
                {
                    result = await _nameAuthorization.Authorize(nameId, requestedAccessLevel);
                    _authorizationResultCache.TryAddNameAuthorizationResult(identityId, nameId, requestedAccessLevel, result);
                }
                
                if (!result.Exists)
                {
                    actionContext.Response = actionContext.Request.CreateErrorResponse(HttpStatusCode.NotFound, "Name Not Found");
                    return;
                }

                if (result.IsUnauthorized)
                {
                    throw new DataSecurityException(result.ReasonCode.CamelCaseToUnderscore());
                }
            }
        }

        static bool TryExtractAuthorizationParameters(HttpActionContext actionContext, out (AccessPermissionLevel minimumPermissionLevel, int nameId) parameters)
        {
            object returnNameIdObject = null;
            var returnNameId = int.MinValue;
            var extracted = false;
            var returnMinimumAccessLevel = AccessPermissionLevel.Select;

            var requireNameAccess = actionContext.ActionDescriptor.GetCustomAttributes<RequiresNameAuthorizationAttribute>().SingleOrDefault();
            if (requireNameAccess != null)
            {
                returnMinimumAccessLevel = requireNameAccess.MinimumAccessPermission;

                var propertyNames = string.IsNullOrWhiteSpace(requireNameAccess.PropertyName)
                    ? RequiresNameAuthorizationAttribute.CommonPropertyNames
                    : new[] {requireNameAccess.PropertyName};

                if (!string.IsNullOrWhiteSpace(requireNameAccess.PropertyPath) && requireNameAccess.PropertyPath.Contains("."))
                {
                    var propertyQueue = new Queue<string>(requireNameAccess.PropertyPath.Split('.'));
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
                        returnNameIdObject = currentObject;
                    }
                }
                else
                {
                    var propertyName = propertyNames.FirstOrDefault(_ => actionContext.ActionArguments.ContainsKey(_));
                    if (propertyName != null)
                    {
                        returnNameIdObject = actionContext.ActionArguments[propertyName];
                    }
                }

                if (returnNameIdObject != null)
                {
                    var val = returnNameIdObject as int? ?? (int.TryParse(returnNameIdObject as string, out int v) ? (int?) v : null);
                    if (val.HasValue)
                    {
                        extracted = true;
                        returnNameId = val.Value;
                    }
                }
            }

            parameters = (returnMinimumAccessLevel, returnNameId);
            return extracted;
        }
    }
}
