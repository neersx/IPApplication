using System;
using System.ComponentModel.Composition;

namespace Inprotech.Web.Portal
{
    [MetadataAttribute]
    public class WebPartFormatterConfigurationAttribute : Attribute
    {
        public WebPartFormatterConfigurationAttribute(string serviceUrl, string template)
        {
            if(string.IsNullOrWhiteSpace(serviceUrl)) throw new ArgumentException("A valid key is required.");
            if(string.IsNullOrWhiteSpace(template)) throw new ArgumentException("A valid template is required.");

            ServiceUrl = serviceUrl;
            Template = template;
        }

        public string ServiceUrl { get; set; }

        public string Template { get; set; }
    }
}