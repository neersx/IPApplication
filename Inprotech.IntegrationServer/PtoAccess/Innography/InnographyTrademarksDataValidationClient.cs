using System;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IInnographyTradeMarksDataValidationClient
    {
        Task<InnographyApiResponse<TrademarkDataValidationResult>> ValidationApi(TrademarkDataValidationRequest[] data);
    }

    public class InnographyTradeMarksDataValidationClient : IInnographyTradeMarksDataValidationClient
    {  
        readonly IInnographyClient _innographyClient;
        readonly InnographySetting _settings;

        public InnographyTradeMarksDataValidationClient(IInnographySettingsResolver settingsResolver, IInnographyClient innographyClient)
        {
            _innographyClient = innographyClient;
            _settings = settingsResolver.Resolve(InnographyEndpoints.TrademarksDv);
        }

        public async Task<InnographyApiResponse<TrademarkDataValidationResult>> ValidationApi(TrademarkDataValidationRequest[] data)
        {
            var dataValidationApi = new Uri(_settings.ApiBase, new Uri($"/tm/data-validation/api/validate/{_settings.PlatformClientId}", UriKind.Relative));
            var apiSettings = new InnographyClientSettings(CryptoAlgorithm.Sha256)
            {
                Version = InnographyTradeMarksApiSettings.TargetApiVersion,
                ClientSecret = _settings.ClientSecret,
                ClientId = _settings.ClientId
            };
            return await _innographyClient.Post<InnographyApiResponse<TrademarkDataValidationResult>>(apiSettings, dataValidationApi, new TrademarkApiRequest<TrademarkDataValidationRequest>
            {
                ClientId = _settings.PlatformClientId,
                Requester = InnographyTradeMarksApiSettings.Requester,
                Destination = InnographyTradeMarksApiSettings.Destination,
                MessageType = InnographyTradeMarksApiSettings.MessageType,
                DataFields = data
            });
        }
    }
}
