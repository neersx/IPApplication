using System;

namespace Inprotech.Infrastructure.Security
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class, AllowMultiple = true)]
    public class RequiresAuthenticationSettingsAttribute : Attribute
    {
        public string AuthModeKey { get; }

        public RequiresAuthenticationSettingsAttribute(string authModeKey)
        {
            AuthModeKey = authModeKey;
        }
    }
}
