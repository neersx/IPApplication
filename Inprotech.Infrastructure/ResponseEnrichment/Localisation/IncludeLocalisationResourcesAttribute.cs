using System;

namespace Inprotech.Infrastructure.ResponseEnrichment.Localisation
{
    [AttributeUsage(AttributeTargets.Method)]
    public class IncludeLocalisationResourcesAttribute : Attribute
    {
        public string ApplicationName { get; private set; }

        public string[] Components { get; private set;  }
             
        public IncludeLocalisationResourcesAttribute(string applicationName, params string[] components)
        {
            ApplicationName = applicationName;

            Components = components ?? new string[0];
        }

        public IncludeLocalisationResourcesAttribute() : this(null)
        {
        }
    }
}