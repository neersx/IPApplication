using System;
using System.Net.Http.Formatting;
using System.Web.Http.Controllers;

namespace Inprotech.Infrastructure.Formatting
{
    /// <summary>
    /// By default Web API configuration removes XmlFormatter.
    /// Decorate the controller with this attribute when responses needs to be formatted 
    /// as XML.
    /// </summary>
    public class UseXmlFormatterAttribute : Attribute, IControllerConfiguration
    {
        public void Initialize(HttpControllerSettings controllerSettings, HttpControllerDescriptor controllerDescriptor)
        {
            if(controllerSettings.Formatters.XmlFormatter == null)
            {
                controllerSettings.Formatters.Add(new XmlMediaTypeFormatter());
            }
        }
    }
}