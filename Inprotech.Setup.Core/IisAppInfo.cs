using System;
using Microsoft.Web.Administration;

namespace Inprotech.Setup.Core
{
    public class IisAppInfo
    {
        public string Site { get; internal set; }

        public string VirtualPath { get; internal set; }

        public string PhysicalPath { get; internal set; }

        public string ApplicationPool { get; internal set; }

        public string Protocols { get; internal set; }

        public string ServiceUser { get; internal set; }

        public bool IsBuiltInServiceUser { get; internal set; }

        public ProcessModelIdentityType IdentityType { get; internal set; }

        public string Username { get; internal set; }

        public string Password { get; internal set; }

        public string BindingUrls { get; internal set; }

        public WebConfig WebConfig { get; internal set; }

        public Version Version { get; internal set; }

        public bool AuthModeToBeSetFromApps { get; internal set; }

        public string GetAuthenticationMode()
        {
            if (AuthModeToBeSetFromApps)
            {
                return WebConfig.Backup != null && WebConfig.Backup.Exists ? WebConfig.Backup.AuthenticationMode : string.Empty;
            }

            return WebConfig.AuthenticationMode;
        }
    }
}