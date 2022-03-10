using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.IntegrationServer.PtoAccess.Innography.SourceChanges;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IInnographyPatentsDataValidationClient
    {
        Task<InnographyApiResponse<ChangeResult>> GuidChangeApi();
        Task<InnographyApiResponse<ValidationResult>> ValidationApi(PatentDataValidationRequest[] innographyIds);
    }

    public class InnographyPatentsDataValidationClient : IInnographyPatentsDataValidationClient
    {
        const string GuidChangeApiTemplate = "/data-validation/guid_changes?date=";
        readonly IInnographyClient _innographyClient;
        readonly IMostRecentlyAppliedChanges _mostRecentlyAppliedChanges;

        readonly InnographySetting _settings;

        public InnographyPatentsDataValidationClient(IInnographySettingsResolver settingsResolver, IInnographyClient innographyClient, IMostRecentlyAppliedChanges mostRecentlyAppliedChanges)
        {
            _innographyClient = innographyClient;
            _mostRecentlyAppliedChanges = mostRecentlyAppliedChanges;

            _settings = settingsResolver.Resolve(InnographyEndpoints.PatentsDv);
        }

        public async Task<InnographyApiResponse<ChangeResult>> GuidChangeApi()
        {
            var since = await _mostRecentlyAppliedChanges.Resolve();

            var api = new Uri(_settings.ApiBase, new Uri($"{GuidChangeApiTemplate}{since:yyyy-MM-dd}&client_id={_settings.PlatformClientId}", UriKind.Relative));

            var apiSettings = new InnographyClientSettings
            {
                Version = InnographyPatentsApiSettings.GuidChangesTargetApiVersion,
                ClientSecret = _settings.ClientSecret,
                ClientId = _settings.ClientId
            };

            return await _innographyClient.Post<InnographyApiResponse<ChangeResult>>(apiSettings, api);
        }

        public async Task<InnographyApiResponse<ValidationResult>> ValidationApi(PatentDataValidationRequest[] innographyIds)
        {
            if (!innographyIds.Any())
            {
                return new InnographyApiResponse<ValidationResult>();
            }

            var apiSettings = new InnographyClientSettings
            {
                Version = InnographyPatentsApiSettings.TargetApiVersion,
                ClientSecret = _settings.ClientSecret,
                ClientId = _settings.ClientId
            };
            var matchingValueApi = new Uri(_settings.ApiBase, new Uri($"/data-validation/validations?client_id={_settings.PlatformClientId}", UriKind.Relative));
            return await _innographyClient.Post<InnographyApiResponse<ValidationResult>>(apiSettings, matchingValueApi, new {patent_data = innographyIds});
        }
    }
}