using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.Web.ExchangeIntegration
{
    public interface IExchangeSettingsResolver
    {
        Task<ExchangeSettingsConfigurationModel> Resolve(HttpRequestMessage request);
    }

    public class ExchangeSettingsResolver : IExchangeSettingsResolver
    {
        readonly IExchangeSiteSettingsResolver _exchangeSiteSettingsResolver;
        readonly IAppSettingsProvider _appSettingsProvider;

        public ExchangeSettingsResolver(IExchangeSiteSettingsResolver exchangeSiteSettingsResolver, IAppSettingsProvider appSettingsProvider)
        {
            _exchangeSiteSettingsResolver = exchangeSiteSettingsResolver;
            _appSettingsProvider = appSettingsProvider;
        }

        public async Task<ExchangeSettingsConfigurationModel> Resolve(HttpRequestMessage request)
        {
            var siteSettings = await _exchangeSiteSettingsResolver.Resolve();

            if (!siteSettings.ExternalSettingExists)
            {
                return new ExchangeSettingsConfigurationModel
                {
                    ExternalSettingExists = false
                };
            }
            
            var passwordExists = !string.IsNullOrWhiteSpace(siteSettings.Settings.Password);
            
            siteSettings.Settings.ExchangeGraph ??= new ExchangeGraph();

            var clientSecretExists = !string.IsNullOrWhiteSpace(siteSettings.Settings.ExchangeGraph?.ClientSecret);
            
            siteSettings.Settings.Password = null;
            
            if (!string.IsNullOrWhiteSpace(siteSettings.Settings.ExchangeGraph?.ClientSecret))
            {
                siteSettings.Settings.ExchangeGraph.ClientSecret = null;
            }

            siteSettings.Settings.ServiceType = string.IsNullOrWhiteSpace(siteSettings.Settings.ServiceType) 
                ? "Ews"
                : siteSettings.Settings.ServiceType;

            var bindingUrls = _appSettingsProvider["BindingUrls"]?.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries) ?? new string[0];

            return new ExchangeSettingsConfigurationModel
            {
                ExternalSettingExists = true,
                Settings = siteSettings.Settings,
                HasValidSettings = siteSettings.HasValidSettings,
                PasswordExists = passwordExists,
                ClientSecretExists = clientSecretExists,
                DefaultSiteUrls = bindingUrls.SelectMany(_ => PossiblePaths(_, request)).Distinct().Where(x => !string.IsNullOrWhiteSpace(x))
            };
        }

        static IEnumerable<string> PossiblePaths(string bindingUrl, HttpRequestMessage request)
        {
            var appPathUri = request.RequestUri
                                    .ReplaceStartingFromSegment("apps", "apps");

            if (bindingUrl.Contains(":80"))
            {
                yield return new Uri("http://localhost") + appPathUri.PathAndQuery.TrimStart('/');
            }
            else if (bindingUrl.Contains(":443"))
            {
                yield return new Uri("https://" + Environment.MachineName) + appPathUri.PathAndQuery.TrimStart('/');
                yield return appPathUri.ToString();
            }
            else
            {
                yield return null;
            }
        }
    }

    public class ExchangeSettingsConfigurationModel
    {  
        public bool ExternalSettingExists { get; set; }
        public ExchangeConfigurationSettings Settings { get; set; }
        public bool HasValidSettings { get; set; }
        public bool PasswordExists { get; set; }
        public bool ClientSecretExists { get; set; }
        public IEnumerable<string> DefaultSiteUrls { get; set; }
    }
}