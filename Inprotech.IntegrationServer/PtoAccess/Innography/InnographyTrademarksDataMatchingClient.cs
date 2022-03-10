using System;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IInnographyTradeMarksDataMatchingClient
    {
        Task<InnographyApiResponse<TrademarkDataResponse>> MatchingApi(TrademarkDataRequest[] data);
    }

    public class InnographyTrademarksDataMatchingClient : IInnographyTradeMarksDataMatchingClient
    {
        readonly IInnographyClient _innographyClient;
        readonly InnographySetting _settings;

        public InnographyTrademarksDataMatchingClient(IInnographySettingsResolver settingsResolver, IInnographyClient innographyClient)
        {
            _innographyClient = innographyClient;
            _settings = settingsResolver.Resolve(InnographyEndpoints.TrademarksDv);
        }

        public async Task<InnographyApiResponse<TrademarkDataResponse>> MatchingApi(TrademarkDataRequest[] data)
        {
            var matchingApi = new Uri(_settings.ApiBase, new Uri($"/tm/data-validation/api/match/{_settings.PlatformClientId}", UriKind.Relative));
            var apiSettings = new InnographyClientSettings(CryptoAlgorithm.Sha256)
            {
                Version = InnographyTradeMarksApiSettings.TargetApiVersion,
                ClientSecret = _settings.ClientSecret,
                ClientId = _settings.ClientId
            };
            return await _innographyClient.Post<InnographyApiResponse<TrademarkDataResponse>>(apiSettings, matchingApi, new TrademarkApiRequest<TrademarkDataRequest>
            {
                ClientId = _settings.PlatformClientId,
                Requester = InnographyTradeMarksApiSettings.TargetApiVersion,
                Destination = InnographyTradeMarksApiSettings.Destination,
                MessageType = InnographyTradeMarksApiSettings.MessageType,
                DataFields = data
            });
        }
    }
}
