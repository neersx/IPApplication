using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;

namespace Inprotech.IntegrationServer.Api
{
    [RequiresApiKey(ExternalApplicationName.InprotechServer, IsOneTimeUse = true)]
    public class ExchangeStatusController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IExchangeIntegrationSettings _settings;
        readonly IStrategy _strategy;

        public ExchangeStatusController(IStrategy strategy, IExchangeIntegrationSettings settings, IDbContext dbContext)
        {
            _strategy = strategy;
            _settings = settings;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("api/exchange/status/{userId}")]
        public async Task<bool> Status(int userId)
        {
            var setting = _settings.ForEndpointTest();
            var exchangeService = _strategy.GetService(Guid.NewGuid(), setting.ServiceType);

            if (setting.ServiceType == KnownImplementations.Ews)
            {
                var mailboxes = await (from m in _dbContext.Set<SettingValues>()
                                       where m.SettingId == KnownSettingIds.ExchangeMailbox &&
                                             m.CharacterValue != null &&
                                             m.User.IsValid
                                       select m.CharacterValue).ToArrayAsync();

                foreach (var mailbox in mailboxes)
                {
                    var result = await exchangeService.CheckStatus(setting, mailbox, userId);

                    if (result)
                    {
                        return true;
                    }
                }
            }
            else
            {
                try
                {
                   return await exchangeService.CheckStatus(setting, null, userId);
                }
                catch
                {
                    return false;
                }
            }

            return false;
        }
    }
}