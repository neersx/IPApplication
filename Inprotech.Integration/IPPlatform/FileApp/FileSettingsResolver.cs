using System;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileSettingsResolver
    {
        FileSettings Resolve();
    }

    public class FileSettingsResolver : IFileSettingsResolver
    {
        readonly IConfigurationSettings _appSettings;
        readonly IGroupedConfig _config;
        readonly ISiteControlReader _siteControlReader;

        public FileSettingsResolver(Func<string, IGroupedConfig> groupedConfig,
                                    ISiteControlReader siteControlReader,
                                    IConfigurationSettings appSettings)
        {
            _siteControlReader = siteControlReader;
            _appSettings = appSettings;
            _config = groupedConfig("InprotechServer.AppSettings");
        }

        public FileSettings Resolve()
        {
            var values = _config.GetValues(KnownAppSettingsKeys.AuthenticationMode);

            var configuredAuthMode = new ConfiguredAuthMode(values[KnownAppSettingsKeys.AuthenticationMode]);

            var fileIntegrationEvent = _siteControlReader.Read<int?>(SiteControls.FILEIntegrationEvent);

            var earliestPriority = _siteControlReader.Read<string>(SiteControls.EarliestPriority) ?? KnownRelations.EarliestPriority;

            if (!configuredAuthMode.SsoEnabled)
            {
                return new FileSettings();
            }

            var fileApiBase = _appSettings["FileBaseApiUrl"];
            if (string.IsNullOrWhiteSpace(fileApiBase))
            {
                fileApiBase = _appSettings[KnownAppSettingsKeys.CpaApiUrl];
            }

            return new FileSettings
            {
                ApiBase = fileApiBase?.TrimEnd('/') + "/fapi/api/v1",
                IsEnabled = true,
                FileIntegrationEvent = fileIntegrationEvent,
                EarliestPriorityRelationship = earliestPriority,
                DesignatedCountryRelationship = KnownRelations.DesignatedCountry1
            };
        }
    }

    public class FileSettings
    {
        public bool IsEnabled { get; set; }

        public int? FileIntegrationEvent { get; set; }

        public string ApiBase { get; set; }

        public string EarliestPriorityRelationship { get; set; }
        
        public string DesignatedCountryRelationship { get; set; }
    }

    public static class FileSettingsExt
    {
        const string ApiCases = "{0}/cases";

        const string ApiSpecificCase = "{0}/cases/{1}";

        const string ApiGetCountryCase = "{0}/cases/{1}/countries/{2}";

        const string ApiPutCountryCases = "{0}/cases/{1}/countries";

        const string ApiGetInstructions = "{0}/cases/{1}/instructions";

        const string ApiGetCountryInstructions = "{0}/cases/{1}/instructions/{2}";

        const string ApiGetDocuments = "{0}/documents/{1}";

        const string ApiCaseBlob = "{0}/cases/blob/{1}";

        const string ApiCaseBlobValidate = "{0}/cases/blob/validate/{1}";

        public static Uri CasesApi(this FileSettings settings, string caseId = null)
        {
            return caseId == null
                ? new Uri(string.Format(ApiCases, settings.ApiBase))
                : new Uri(string.Format(ApiSpecificCase, settings.ApiBase, caseId));
        }

        public static Uri CasesBlobApi(this FileSettings settings, int caseId)
        {
            return new Uri(string.Format(ApiCaseBlob, settings.ApiBase, caseId));
        }

        public static Uri CasesBlobValidateApi(this FileSettings settings, Guid blobUid)
        {
            return new Uri(string.Format(ApiCaseBlobValidate, settings.ApiBase, blobUid.ToString("N")));
        }

        public static Uri CountryCaseApi(this FileSettings settings, string caseId, string countryCode)
        {
            return new Uri(string.Format(ApiGetCountryCase, settings.ApiBase, caseId, countryCode));
        }

        public static Uri UpdateCountrySelectionApi(this FileSettings settings, string caseId)
        {
            return new Uri(string.Format(ApiPutCountryCases, settings.ApiBase, caseId));
        }

        public static Uri InstructionsApi(this FileSettings settings, string caseId, string countryCode = null)
        {
            return countryCode == null
                ? new Uri(string.Format(ApiGetInstructions, settings.ApiBase, caseId))
                : new Uri(string.Format(ApiGetCountryInstructions, settings.ApiBase, caseId, countryCode));
        }

        public static Uri DocumentsApi(this FileSettings settings, string documentId)
        {
            return new Uri(string.Format(ApiGetDocuments, settings.ApiBase, documentId));
        }

        public static void EnsureRequiredKeysAvailable(this IFileSettingsResolver fileSettingsResolver)
        {
            var fileSettings = fileSettingsResolver.Resolve();

            if (fileSettings.IsEnabled) return;

            throw new Exception("FILE connectivity requires the Firm to have already configured for The IP Platform access.");
        }
    }
}