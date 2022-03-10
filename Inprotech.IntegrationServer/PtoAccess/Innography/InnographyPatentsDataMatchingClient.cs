using System;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IInnographyPatentsDataMatchingClient
    {
        Task<InnographyApiResponse<IpIdResult>> IpIdApi(InnographyIdApiRequest request);
    }
    public class InnographyPatentsDataMatchingClient : IInnographyPatentsDataMatchingClient
    {  
        readonly IInnographyClient _innographyClient;
        readonly InnographySetting _settings;

        public InnographyPatentsDataMatchingClient(IInnographySettingsResolver settingsResolver, IInnographyClient innographyClient)
        {
            _innographyClient = innographyClient;

            _settings = settingsResolver.Resolve(InnographyEndpoints.PatentsDv);
        }

        public async Task<InnographyApiResponse<IpIdResult>> IpIdApi(InnographyIdApiRequest request)
        {
            var innographyIdApi = new Uri(_settings.ApiBase, new Uri($"/matching/ipids?client_id={_settings.PlatformClientId}", UriKind.Relative));
            var apiSettings = new InnographyClientSettings
            {
                Version = InnographyPatentsApiSettings.TargetApiVersion,
                ClientSecret = _settings.ClientSecret,
                ClientId = _settings.ClientId
            };
            return await _innographyClient.Post<InnographyApiResponse<IpIdResult>>(apiSettings, innographyIdApi, request);
        }
    }
}