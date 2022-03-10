using System;
using System.Linq;
using System.Xml.Linq;

namespace Inprotech.Setup.Core
{
    public interface IAuthenticationMode
    {
        string Resolve(XElement config);

        string ResolveFromBackupConfig(XElement config);
    }

    class AuthenticationMode : IAuthenticationMode
    {
        public string Resolve(XElement config)
        {
            if (config == null)
                return string.Empty;

            var authenticationModes = (AuthenticationModeFromRelease8AndBeyond(config) ?? AuthenticationModeFromOlderVersions(config)).Attribute("mode")?.Value;

            return authenticationModes;
        }

        static XElement AuthenticationModeFromOlderVersions(XElement config)
        {
            return (from web in config.Elements("system.web")
                where web.Elements("authentication").Any()
                select web.Element("authentication"))
                .Single();
        }

        static XElement AuthenticationModeFromRelease8AndBeyond(XElement config)
        {
            return (from loc in config.Elements("location")
                from web in loc.Elements("system.web")
                where web.Elements("authentication").Any()
                select web.Element("authentication"))
                .SingleOrDefault();
        }

        public string ResolveFromBackupConfig(XElement config)
        {
            var authenticationModes = Resolve(config);

            if (IsFormsWithPsedoSso(config))
            {
                authenticationModes = string.Join(",", authenticationModes, Constants.AuthenticationModeKeys.Windows);
            }

            return authenticationModes;
        }

        static bool IsFormsWithPsedoSso(XElement config)
        {
            var isPsedoSso = (from appSettingSection in config.Elements("appSettings")
             from add in appSettingSection.Elements("add")
             where add.Attribute("key")?.Value == "SingleSignOn"
             select add.Attribute("value")?.Value).SingleOrDefault();

            return !string.IsNullOrWhiteSpace(isPsedoSso) && Convert.ToBoolean(isPsedoSso);
        }
    }
}