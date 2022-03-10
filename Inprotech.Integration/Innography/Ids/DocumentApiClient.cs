using System;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.Analytics;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Integration.Innography.Ids
{
    public enum IpType
    {
        Patent,
        Design
    }

    public enum DocumentType
    {
        Publication,
        PublicationOfApplication,
        Application,
        Grant
    }

    public interface IDocumentApiClient
    {
        Task<DocumentApiResponse> Documents(string countryCode, string number, string kindCode);

        Task<Stream> Pdf(string countryCode, string number, string kindCode);
    }

    public class DocumentApiClient : IDocumentApiClient
    {
        const string TargetApiVersion = "0.8";

        readonly IInnographyClient _innographyClient;
        readonly IBus _bus;
        readonly InnographySetting _settings;
        
        public DocumentApiClient(IInnographySettingsResolver settingsResolver, IInnographyClient innographyClient, IBus bus)
        {
            _innographyClient = innographyClient;
            _bus = bus;
            _settings = settingsResolver.Resolve(InnographyEndpoints.Documents);
        }

        public async Task<DocumentApiResponse> Documents(string countryCode, string number, string kindCode)
        {
            _settings.EnsureRequiredKeysAvailable();

            if (string.IsNullOrWhiteSpace(countryCode)) throw new ArgumentNullException(nameof(countryCode));
            if (string.IsNullOrWhiteSpace(number)) throw new ArgumentNullException(number);
            
            var api = new Uri(_settings.ApiBase, new Uri(BuildPath("documents", countryCode, number, kindCode) + "?client_id=" + _settings.PlatformClientId, UriKind.Relative));

            var apiSettings = new InnographyClientSettings
            {
                Version = TargetApiVersion,
                ClientSecret = _settings.ClientSecret,
                ClientId = _settings.ClientId
            };
            var response = await _innographyClient.Get<DocumentApiResponse>(apiSettings, api);

            await _bus.PublishAsync(new TransactionalAnalyticsMessage
            {
                EventType = TransactionalEventTypes.PriorArtIdsDocuments,
                Value = TransactionalEventTypes.PriorArtIdsDocuments
            });

            return response;
        }

        public async Task<Stream> Pdf(string countryCode, string number, string kindCode)
        {
            _settings.EnsureRequiredKeysAvailable();

            if (string.IsNullOrWhiteSpace(countryCode)) throw new ArgumentNullException(nameof(countryCode));
            if (string.IsNullOrWhiteSpace(number)) throw new ArgumentNullException(number);

            var api = new Uri(_settings.ApiBase, new Uri(BuildPath("documents", "pdf", countryCode, number, kindCode)+ "?client_id=" + _settings.PlatformClientId, UriKind.Relative));

            var apiSettings = new InnographyClientSettings
            {
                Version = TargetApiVersion,
                ClientSecret = _settings.ClientSecret,
                ClientId = _settings.ClientId
            };

            var response = await _innographyClient.Get<Stream>(apiSettings, api);

            await _bus.PublishAsync(new TransactionalAnalyticsMessage
            {
                EventType = TransactionalEventTypes.PriorArtIdsPdf,
                Value = TransactionalEventTypes.PriorArtIdsPdf
            });

            return response;
        }
        
        static string BuildPath(params string[] path)
        {
            return "/" + string.Join(@"/",
                               path.Where(_ => !string.IsNullOrWhiteSpace(_))
                                   .Select(Uri.EscapeDataString));
        }
    }
    
    public class DocumentApiResponse
    {
        public string Message { get; set; }

        public string Status { get; set; }
        
        public Result Result { get; set; }

        public string ErrorMessage { get; set; }

        [OnError]
        internal void OnError(StreamingContext context, ErrorContext errorContext)
        {
            var member = errorContext.Member as string;
            if (member == "result")
            {
                ErrorMessage = errorContext.Error.Message;
                errorContext.Handled = true;
            }
        }
    }
}