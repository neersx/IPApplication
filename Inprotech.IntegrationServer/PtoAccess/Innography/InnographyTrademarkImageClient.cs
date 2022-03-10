using System;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IInnographyTradeMarksImageClient
    {
        Task<InnographyApiResponse<TrademarkImage>> ImageApi(string ipid);
    }

    public class InnographyTrademarksImageClient : IInnographyTradeMarksImageClient
    {
        readonly IInnographyClient _innographyClient;
        readonly InnographySetting _settings;

        public InnographyTrademarksImageClient(IInnographySettingsResolver settingsResolver, IInnographyClient innographyClient)
        {
            _innographyClient = innographyClient;
            _settings = settingsResolver.Resolve(InnographyEndpoints.TrademarksDv);
        }

        public async Task<InnographyApiResponse<TrademarkImage>> ImageApi(string ipid)
        {
            var imageApi = new Uri(_settings.ApiBase, new Uri($"/tm/images/{ipid}", UriKind.Relative));
            var apiSettings = new InnographyClientSettings(CryptoAlgorithm.Sha256)
            {
                Version = InnographyTradeMarksApiSettings.TargetApiVersion,
                ClientSecret = _settings.ClientSecret,
                ClientId = _settings.ClientId
            };
            return await _innographyClient.Get<InnographyApiResponse<TrademarkImage>>(apiSettings, imageApi);
        }
    }
}
