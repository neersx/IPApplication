using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public interface IPersistedCredentialsResolver
    {
        Task<DmsCredential> Resolve();
    }

    public class PersistedCredentialsResolver : IPersistedCredentialsResolver
    {
        readonly ICryptoService _cryptoService;
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public PersistedCredentialsResolver(IDbContext dbContext, ICryptoService cryptoService, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
            _securityContext = securityContext;
        }

        public Task<DmsCredential> Resolve()
        {
            var userId = _securityContext.User.Id;
            var dmsCredentials = (from sv in _dbContext.Set<SettingValues>()
                                  where sv.User != null && sv.User.Id == userId
                                                        && (sv.SettingId == KnownSettingIds.WorkSiteLogin || sv.SettingId == KnownSettingIds.WorkSitePassword)
                                  select new
                                  {
                                      sv.SettingId,
                                      sv.CharacterValue
                                  }).ToDictionary(k => k.SettingId, v => v.CharacterValue);

            return Task.FromResult(new DmsCredential
            {
                UserName = dmsCredentials.Get(KnownSettingIds.WorkSiteLogin),
                Password = Decrypt(dmsCredentials.Get(KnownSettingIds.WorkSitePassword))
            });
        }

        string Decrypt(string raw)
        {
            return !string.IsNullOrWhiteSpace(raw) ? _cryptoService.Decrypt(raw, true) : null;
        }
    }
}