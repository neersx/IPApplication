using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Hosting;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public interface IPrivatePairService
    {
        Task CheckOrCreateAccount();
        Task<string> DispatchCrawlerService(string sponsoredEmail, string sponsoredPassword, string secretCode, string sponsorName, string[] customerNumbers);
        Task DecommissionCrawlerService(string serviceId);
        Task DeleteAccount();
        Task<IEnumerable<Message>> DequeueMessages();
        Task<(bool Updated, string Reason)> RequeueMessages(DateTime fromDate, DateTime toDate);

        Task<(bool Updated, string Reason)> UpdateOneTimeGlobalAccountSettings(DateTime requeueFromDate, DateTime requeueToDate, string newQueueId, string newQueueSecret, string queueUrl);

        Task<byte[]> DownloadDocumentData(string serviceId, LinkInfo info);
        Task<(bool Updated, string Reason)> UpdateServiceDetails(string serviceId, string password, string secretCode, string[] customerNumbers);
        bool IsServiceRegistered(string serviceId);
    }

    public class PrivatePairService : IPrivatePairService
    {
        const string TargetApiVersion = "0.9";
        const string ServiceType = "uspto";
        readonly ICryptographyService _cryptographyService;
        readonly Func<HostInfo> _hostInfoResolver;
        readonly IInnographyClient _innographyClient;

        readonly InnographyPrivatePairSetting _resolvedSettings;
        readonly IInnographyPrivatePairSettings _settings;

        public PrivatePairService(IInnographyPrivatePairSettings settings,
                                  IInnographyClient innographyClient,
                                  ICryptographyService cryptographyService,
                                  Func<HostInfo> hostInfoResolver)
        {
            _settings = settings;
            _innographyClient = innographyClient;
            _cryptographyService = cryptographyService;
            _hostInfoResolver = hostInfoResolver;
            _resolvedSettings = settings.Resolve();
        }

        public async Task CheckOrCreateAccount()
        {
            if (_resolvedSettings.PrivatePairSettings.IsAccountSettingsValid) return;

            var account = await CreateAccount();
            if (!account.IsValid) return;

            _resolvedSettings.PrivatePairSettings.ClientId = account.AccountId;
            _resolvedSettings.PrivatePairSettings.ClientSecret = account.AccountSecret;
            _resolvedSettings.PrivatePairSettings.QueueId = account.QueueAccessId;
            _resolvedSettings.PrivatePairSettings.QueueSecret = account.QueueAccessSecret;
            _resolvedSettings.PrivatePairSettings.QueueUrl = account.QueueUrl;
            _resolvedSettings.PrivatePairSettings.SqsRegion = account.SqsRegion;
            _resolvedSettings.PrivatePairSettings.ValidEnvironment = _hostInfoResolver().DbIdentifier;

            await _settings.Save(_resolvedSettings);
        }

        public async Task DeleteAccount()
        {
            if (!_resolvedSettings.PrivatePairSettings.IsAccountSettingsValid)
            {
                return;
            }

            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            if (string.Equals(_resolvedSettings.ValidEnvironment, dbIdentifier, StringComparison.CurrentCultureIgnoreCase))
            {
                var api = Api($"/private-pair/account/{AccountId}");

                var apiSettings = DefaultClientSettings();

                await _innographyClient.Delete(apiSettings, api);
            }

            _resolvedSettings.PrivatePairSettings = new PrivatePairExternalSettings();
            _resolvedSettings.ValidEnvironment = dbIdentifier;

            await _settings.Save(_resolvedSettings);
        }

        public async Task<string> DispatchCrawlerService(string sponsoredEmail, string sponsoredPassword, string secretCode, string sponsorName, string[] customerNumbers)
        {
            var keySet = _cryptographyService.GenerateRsaKeys(4096);

            var service = await CreateService(new PrivatePairCredentials
            {
                Email = sponsoredEmail,
                Password = sponsoredPassword,
                SecretCode = secretCode,
                Sponsor = sponsorName,
                PublicKey = keySet.Public,
                CustomerNumbers = customerNumbers.ToDictionary(k => k, v => new string[0])
            });

            if (service.IsValid)
            {
                _resolvedSettings.PrivatePairSettings.Services[service.ServiceId] = new ServiceCredentials
                {
                    Id = service.ServiceId,
                    SponsoredEmail = sponsoredEmail,
                    SponsorName = sponsorName,
                    KeySet = keySet
                };

                await _settings.Save(_resolvedSettings);

                return service.ServiceId;
            }

            return null;
        }

        public async Task<(bool Updated, string Reason)> UpdateServiceDetails(string serviceId, string password, string secretCode, string[] customerNumbers)
        {
            if (!IsServiceRegistered(serviceId)) return (false, null);

            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            if (!string.Equals(_resolvedSettings.ValidEnvironment, dbIdentifier, StringComparison.CurrentCultureIgnoreCase))
            {
                return (false, "invalidEnvironment");
            }

            var api = Api($"/private-pair/account/{AccountId}/service/uspto/{serviceId.Trim()}");
            var apiSettings = DefaultClientSettings();

            var serviceDetail = new PrivatePairServiceModel
            {
                Password = string.IsNullOrWhiteSpace(password) ? null : password,
                Secret = string.IsNullOrWhiteSpace(secretCode) ? null : secretCode,
                CustomerNumbers = customerNumbers?.ToDictionary(k => k, v => new string[0])
            };

            var response = await _innographyClient.Patch<string>(apiSettings, api, serviceDetail);
            return (string.Equals(Parse<PrivatePairApiResponse>(response).Status, "success", StringComparison.InvariantCultureIgnoreCase), null);
        }

        public async Task DecommissionCrawlerService(string serviceId)
        {
            if (serviceId == null) throw new ArgumentNullException(nameof(serviceId));

            if (!IsServiceRegistered(serviceId)) return;

            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            if (string.Equals(_resolvedSettings.ValidEnvironment, dbIdentifier, StringComparison.CurrentCultureIgnoreCase))
            {
                await DeleteService(serviceId);
            }

            _resolvedSettings.PrivatePairSettings.Services.Remove(serviceId);

            await _settings.Save(_resolvedSettings);
        }

        public async Task<IEnumerable<Message>> DequeueMessages()
        {
            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            if (!string.Equals(_resolvedSettings.ValidEnvironment, dbIdentifier, StringComparison.CurrentCultureIgnoreCase))
            {
                return new Message[0];
            }

            var api = Api($"/private-pair/account/{_resolvedSettings.PrivatePairSettings.ClientId}/queue");

            var apiSettings = DefaultClientSettings(_ =>
                                                        _.AdditionalHeaders = new Dictionary<string, string>
                                                        {
                                                            {"X-Queue-Access-ID", _resolvedSettings.PrivatePairSettings.QueueId},
                                                            {"X-Queue-Access-Secret", _resolvedSettings.PrivatePairSettings.QueueSecret}
                                                        });

            var response = await _innographyClient.Get<string>(apiSettings, api);
            return Parse<PrivatePairApiResponse<Messages>>(response).Result.MessageArray;
        }

        public async Task<(bool Updated, string Reason)> UpdateOneTimeGlobalAccountSettings(DateTime requeueFromDate, DateTime requeueToDate, string newQueueId, string newQueueSecret, string queueUrl)
        {
            var isRequeued = await RequeueMessagesInternal(requeueFromDate, requeueToDate, newQueueId, newQueueSecret);
            if (isRequeued.Updated)
            {
                _resolvedSettings.PrivatePairSettings.QueueId = newQueueId;
                _resolvedSettings.PrivatePairSettings.QueueSecret = newQueueSecret;
                _resolvedSettings.PrivatePairSettings.QueueUrl = queueUrl;

                await _settings.Save(_resolvedSettings);
            }

            return isRequeued;
        }

        public async Task<(bool Updated, string Reason)> RequeueMessages(DateTime fromDate, DateTime toDate)
        {
            return await RequeueMessagesInternal(fromDate, toDate);
        }

        async Task<(bool Updated, string Reason)> RequeueMessagesInternal(DateTime fromDate, DateTime toDate, string newQueueId = null, string newQueueSecret = null)
        {
            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            if (!string.Equals(_resolvedSettings.ValidEnvironment, dbIdentifier, StringComparison.CurrentCultureIgnoreCase))
            {
                return (false, "invalidEnvironment");
            }

            var dateFormat = "yyyy/MM/dd";

            var api = Api($"/private-pair/account/{_resolvedSettings.PrivatePairSettings.ClientId}/queue");

            var apiSettings = DefaultClientSettings(_ =>
                                                        _.AdditionalHeaders = new Dictionary<string, string>
                                                        {
                                                            {"X-Queue-Access-ID", newQueueId ?? _resolvedSettings.PrivatePairSettings.QueueId},
                                                            {"X-Queue-Access-Secret", newQueueSecret ?? _resolvedSettings.PrivatePairSettings.QueueSecret}
                                                        });

            var response = await _innographyClient.Post<string>(apiSettings, api, new
            {
                from = fromDate.ToString(dateFormat),
                to = toDate.ToString(dateFormat)
            });
            return (string.Equals(Parse<PrivatePairApiResponse>(response).Status, "success", StringComparison.InvariantCultureIgnoreCase), null);
        }

        public async Task<byte[]> DownloadDocumentData(string serviceId, LinkInfo info)
        {
            if (serviceId == null) throw new ArgumentNullException(nameof(serviceId));

            if (!IsServiceRegistered(serviceId)) return null;

            var privateKey = _resolvedSettings.PrivatePairSettings.Services[serviceId].KeySet.Private;
            var apiSettings = DefaultClientSettings();

            var singleEncode = Uri.EscapeDataString(info.Link);
            var doubleEncode = Uri.EscapeDataString(singleEncode);
            var api = Api($"/private-pair/account/{AccountId}/service/{ServiceType}/{serviceId}/document/{doubleEncode}");

            var encryptedDocument = await _innographyClient.Download(apiSettings, api);

            return DecryptFileData(encryptedDocument, privateKey, info.Decrypter, info.Iv);
        }

        public bool IsServiceRegistered(string serviceId) => _resolvedSettings.PrivatePairSettings.Services.ContainsKey(serviceId);

        async Task<Account> CreateAccount()
        {
            var api = Api("/private-pair/account");

            var apiSettings = new InnographyClientSettings
            {
                Version = TargetApiVersion,
                ClientSecret = _resolvedSettings.ClientSecret,
                ClientId = _resolvedSettings.ClientId,
                ServiceType = ServiceType
            };

            var response = await _innographyClient.Post<string>(apiSettings, api);

            return Parse<PrivatePairApiResponse<Account>>(response).Result;
        }

        async Task<Service> CreateService(PrivatePairCredentials credentials)
        {
            var api = Api($"/private-pair/account/{AccountId}/service/{ServiceType}");

            var apiSettings = DefaultClientSettings();

            var response = await _innographyClient.Post<string>(apiSettings, api, credentials);

            return Parse<PrivatePairApiResponse<Service>>(response).Result;
        }

        async Task DeleteService(string serviceId)
        {
            var api = Api($"/private-pair/account/{AccountId}/service/{ServiceType}/{serviceId}");

            var apiSettings = DefaultClientSettings();

            await _innographyClient.Delete(apiSettings, api);
        }

        string AccountId => _resolvedSettings.PrivatePairSettings.ClientId;

        Uri Api(string api)
        {
            var a = _resolvedSettings.PrivatePairApiBase.ToString().TrimEnd('/') + api;
            return new Uri(a);
        }

        InnographyClientSettings DefaultClientSettings(Action<InnographyClientSettings> additionalSettings = null)
        {
            var settings = new InnographyClientSettings
            {
                Version = TargetApiVersion,
                ClientSecret = _resolvedSettings.PrivatePairSettings.ClientSecret,
                ClientId = _resolvedSettings.PrivatePairSettings.ClientId,
                ServiceType = ServiceType
            };
            additionalSettings?.Invoke(settings);
            return settings;
        }

        byte[] DecryptFileData(byte[] fileData, string privateKey, string key, string iv)
        {
            var keyBytes = Convert.FromBase64String(key);
            var ivBytes = Convert.FromBase64String(iv);
            var keyx = _cryptographyService.RSADecrypt(keyBytes, privateKey);
            var ivx = _cryptographyService.RSADecrypt(ivBytes, privateKey);

            return _cryptographyService.AESDecrypt(fileData, keyx, ivx);
        }

        static T Parse<T>(string data)
        {
            try
            {
                return JsonConvert.DeserializeObject<T>(data);
            }
            catch (Exception ex)
            {
                throw new PrivatePairServiceException(data, ex);
            }
        }
    }

    [SuppressMessage("Microsoft.Usage", "CA2240:ImplementISerializableCorrectly")]
    [SuppressMessage("Microsoft.Usage", "CA2229:Implement serialization constructors")]
    [Serializable]
    public class PrivatePairServiceException : Exception
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public PrivatePairServiceException(string data, Exception innerException)
            : base("Innography Private PAIR service error. ", innerException)
        {
            Data.Add("ServiceResponseData", data);
        }
    }
}