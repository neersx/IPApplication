using System;
using System.Net.Http.Formatting;
using System.Web.Http.Controllers;

namespace Inprotech.Infrastructure.Formatting
{
    /// <summary>
    /// By default Web API configuration sets CamelCaseContractResolver for JSON formatter.
    /// Use this attribute on the controller when this behavior is not desireable.
    /// </summary>
    [AttributeUsage(AttributeTargets.Class)]
    public class UseDefaultContractResolverAttribute : Attribute, IControllerConfiguration
    {
        public void Initialize(HttpControllerSettings controllerSettings, HttpControllerDescriptor controllerDescriptor)
        {
            controllerSettings.Formatters.Remove(controllerSettings.Formatters.JsonFormatter);
            controllerSettings.Formatters.Add(new JsonMediaTypeFormatter());
        }
    }
}