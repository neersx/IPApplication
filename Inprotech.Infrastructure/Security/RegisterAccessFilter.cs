using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Autofac.Integration.WebApi;

namespace Inprotech.Infrastructure.Security
{
    public class RegisterAccessFilter : IAutofacActionFilter
    {
        readonly IRegisterAccess _registerAccess;

        public RegisterAccessFilter(IRegisterAccess registerAccess)
        {
            _registerAccess = registerAccess;
        }

        public Task OnActionExecutedAsync(HttpActionExecutedContext actionExecutedContext, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }

        public async Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            if (actionContext == null) throw new ArgumentNullException(nameof(actionContext));

            if (TryExtractAuthorizationParameters(actionContext, out int caseId))
            {
                await _registerAccess.ForCase(caseId);
            }
        }

        static bool TryExtractAuthorizationParameters(HttpActionContext actionContext, out int caseId)
        {
            object returnCaseIdObject = null;
            var returnCaseId = int.MinValue;
            var extracted = false;

            var requireCaseAccess = actionContext.ActionDescriptor.GetCustomAttributes<RegisterAccessAttribute>().SingleOrDefault();
            if (requireCaseAccess != null)
            {
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

            caseId = returnCaseId;
            return extracted;
        }
    }
}