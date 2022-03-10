using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion
{
    public class SystemInfoResponseEnricher : IResponseEnricher
    {
        readonly IConfigurationSettings _config;
        readonly IAppVersion _appVersion;
        readonly ISiteControlReader _siteControlReader;

        public SystemInfoResponseEnricher(IConfigurationSettings config, IAppVersion appVersion, ISiteControlReader siteControlReader)
        {
            _config = config;
            _appVersion = appVersion;
            _siteControlReader = siteControlReader;
        }

        public Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            if (actionExecutedContext == null) throw new ArgumentNullException(nameof(actionExecutedContext));
            if (enrichment == null) throw new ArgumentNullException(nameof(enrichment));

            var integrationVersion = _siteControlReader.Read<string>(SiteControls.IntegrationVersion);
            enrichment.Add("systemInfo", new
            {
                releaseYear = _appVersion.CurrentReleaseYear,
                appVersion = _appVersion.CurrentVersionFormatted,
                inprotechVersion = GetInprotechVersion(),
                databaseVersion = GetDatabaseVersion(),
                integrationVersion
            });

            return Task.FromResult(0);
        }

        string GetInprotechVersion()
        {
            var version = _config["InprotechVersion"];
            var inprotechVersionFriendlyName = _config["InprotechVersionFriendlyName"];
            var inprotechRelease = string.IsNullOrWhiteSpace(version) ? string.Empty : $"v{version}";

            return string.IsNullOrWhiteSpace(inprotechVersionFriendlyName) ? inprotechRelease : $"{inprotechRelease} ({inprotechVersionFriendlyName})";
        }

        string GetDatabaseVersion()
        {
            var dbReleaseVersion = _siteControlReader.Read<string>(SiteControls.DBReleaseVersion);
            var dbReleaseRevision = _siteControlReader.Read<string>(SiteControls.DBReleaseRevision);
            var dbRelease = string.IsNullOrWhiteSpace(dbReleaseVersion) ? string.Empty : $"{dbReleaseVersion}";

            return string.IsNullOrWhiteSpace(dbReleaseRevision) ? dbRelease : $"{dbRelease} ({dbReleaseRevision})";
        }

    }
}