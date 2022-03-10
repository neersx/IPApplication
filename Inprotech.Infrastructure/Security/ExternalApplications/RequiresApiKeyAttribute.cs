using System;

namespace Inprotech.Infrastructure.Security.ExternalApplications
{
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = false)]
    public class RequiresApiKeyAttribute : Attribute
    {
        public RequiresApiKeyAttribute(ExternalApplicationName externalApplicationName, bool userRequired = false)
        {
            ExternalApplicationName = externalApplicationName;
            UserRequired = userRequired;
        }

        public ExternalApplicationName ExternalApplicationName { get; private set; }

        public bool UserRequired { get; private set; }

        public bool IsOneTimeUse { get; set; }
    }
}