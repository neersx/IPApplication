using System.Collections.Generic;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Newtonsoft.Json;

namespace Inprotech.Web.Portal
{
    [Authorize]
    [RoutePrefix("api/portal")]
    public class HelpViewController : ApiController
    {
        readonly IHelpLinkResolver _helpLink;
        readonly IConfigurationSettings _appSettings;
        readonly IFileHelpers _fileHelpers;
        readonly IConfigSettings _configSettings;
        public HelpViewController(IHelpLinkResolver helpLink, IConfigurationSettings appSettings, IFileHelpers fileHelpers, IConfigSettings configSettings)
        {
            _helpLink = helpLink;
            _appSettings = appSettings;
            _fileHelpers = fileHelpers;
            _configSettings = configSettings;
        }

        [NoEnrichment]
        [Route("help")]
        public dynamic GetHelpData()
        {
            var cookieDeclarationActive = false;
            var setupSettings = _configSettings[KnownSetupSettingKeys.ConfigurationKey];
            if (!string.IsNullOrEmpty(setupSettings))
            {
                var cookieConsent = JsonConvert.DeserializeObject<Dictionary<string, string>>(setupSettings);
                if (cookieConsent != null && cookieConsent.ContainsKey(KnownSetupSettingKeys.CookieDeclarationHook))
                {
                    cookieDeclarationActive = !string.IsNullOrEmpty(cookieConsent[KnownSetupSettingKeys.CookieDeclarationHook]);
                }
            }
            return new
            {
                InprotechHelpLink = _helpLink.Resolve(),
                WikiHelpLink = _appSettings[KnownAppSettingsKeys.InprotechWikiLink],
                ContactUsEmailAddress = _appSettings[KnownAppSettingsKeys.ContactUsEmailAddress],
                Credits = _fileHelpers.ReadAllLines("../App License Attributions.txt"),
                CookieConsentActive = cookieDeclarationActive
            };
        }
    }
}