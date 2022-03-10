using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography
{
    public interface IInnographySettingsPersister
    {
        Task AddOrUpdate(string providerName, dynamic data);

        Task SecureAddOrUpdate(string providerName, dynamic data);
    }

    public class InnographySettingsPersister : IInnographySettingsPersister
    {
        readonly ICryptoService _cryptoService;
        readonly IDbContext _dbContext;

        public InnographySettingsPersister(IDbContext dbContext, ICryptoService cryptoService)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
        }

        public async Task AddOrUpdate(string providerName, dynamic data)
        {
            if (string.IsNullOrWhiteSpace(providerName)) throw new ArgumentNullException(nameof(providerName));
            if (!providerName.StartsWith("Innography")) throw new ArgumentException(@"Should start with Innography", nameof(providerName));

            await AddOrUpdate(providerName, data, false);
        }

        public async Task SecureAddOrUpdate(string providerName, dynamic data)
        {
            if (string.IsNullOrWhiteSpace(providerName)) throw new ArgumentNullException(nameof(providerName));
            if (!providerName.StartsWith("Innography")) throw new ArgumentException(@"Should start with Innography", nameof(providerName));

            await AddOrUpdate(providerName, data, true);
        }

        async Task AddOrUpdate(string providerName, dynamic data, bool withEncryption)
        {
            var es = _dbContext.Set<ExternalSettings>();

            var settings = es.SingleOrDefault(_ => _.ProviderName == providerName) ??
                           es.Add(new ExternalSettings(providerName));

            if (data == null)
            {
                settings.Settings = null;
            }
            else
            {
                var raw = JsonConvert.SerializeObject(data);

                settings.Settings =
                    withEncryption
                        ? _cryptoService.Encrypt(raw)
                        : raw;
            }

            settings.IsComplete = settings.Settings != null;
            await _dbContext.SaveChangesAsync();
        }
    }
}