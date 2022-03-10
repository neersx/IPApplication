using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.ExchangeIntegration
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.ExchangeIntegrationAdministration)]
    [RoutePrefix("api/exchange/configuration")]
    public class ExchangeConfigurationController : ApiController
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly IExchangeSettingsResolver _exchangeSettingsResolver;
        readonly ISecurityContext _context;
        readonly ICryptoService _dataProtectionService;
        readonly IDbContext _dbContext;
        readonly IIntegrationServerClient _integrationServerClient;

        public ExchangeConfigurationController(IDbContext dbContext,
                                               ICryptoService dataProtectionService,
                                               IIntegrationServerClient integrationServerClient,
                                               ISecurityContext context,
                                               IAppSettingsProvider appSettingsProvider,
                                               IExchangeSettingsResolver exchangeSettingsResolver
        )
        {
            _dbContext = dbContext;
            _dataProtectionService = dataProtectionService;
            _integrationServerClient = integrationServerClient;
            _context = context;
            _appSettingsProvider = appSettingsProvider;
            _exchangeSettingsResolver = exchangeSettingsResolver;
        }

        [HttpGet]
        [Route("view")]
        public async Task<dynamic> GetExchangeSettings()
        {
            var r = await _exchangeSettingsResolver.Resolve(Request);

            if (!r.ExternalSettingExists) return new ExchangeConfigurationSettings();

            return r;
        }

        [HttpPost]
        [Route("save")]
        public dynamic SaveExchangeSettings(ExchangeConfigurationSettings saveConfiguration)
        {
            if (saveConfiguration == null) throw new ArgumentNullException(nameof(saveConfiguration));

            if (!string.IsNullOrWhiteSpace(saveConfiguration.Password))
            {
                saveConfiguration.Password = _dataProtectionService.Encrypt(saveConfiguration.Password);
            }

            if (!string.IsNullOrWhiteSpace(saveConfiguration.ExchangeGraph?.ClientSecret))
            {
                saveConfiguration.ExchangeGraph.ClientSecret = _dataProtectionService.Encrypt(saveConfiguration.ExchangeGraph.ClientSecret);
            }

            var externalSettings = _dbContext.Set<ExternalSettings>().SingleOrDefault(v => v.ProviderName == KnownExternalSettings.ExchangeSetting);
            if (externalSettings == null)
            {
                _dbContext.Set<ExternalSettings>()
                          .Add(new ExternalSettings(KnownExternalSettings.ExchangeSetting)
                          {
                              Settings = JObject.FromObject(saveConfiguration).ToString(),
                              IsComplete = true
                          });
            }
            else
            {
                var t = JObject.Parse(externalSettings.Settings).ToObject<ExchangeConfigurationSettings>();
                t.IsDraftEmailEnabled = saveConfiguration.IsDraftEmailEnabled;
                t.IsBillFinalisationEnabled = saveConfiguration.IsBillFinalisationEnabled;
                t.IsReminderEnabled = saveConfiguration.IsReminderEnabled;
                t.ServiceType = saveConfiguration.ServiceType;

                if (saveConfiguration.ServiceType == "Graph" && saveConfiguration.ExchangeGraph != null)
                {
                    t.ExchangeGraph = t.ExchangeGraph ?? new ExchangeGraph();
                    t.ExchangeGraph.TenantId = saveConfiguration.ExchangeGraph.TenantId;
                    t.ExchangeGraph.ClientId = saveConfiguration.ExchangeGraph.ClientId;
                    if (!string.IsNullOrWhiteSpace(saveConfiguration.ExchangeGraph.ClientSecret))
                    {
                        t.ExchangeGraph.ClientSecret = saveConfiguration.ExchangeGraph.ClientSecret;
                    }
                }
                else
                {
                    t.Domain = saveConfiguration.Domain;
                    t.Server = saveConfiguration.Server;
                    t.UserName = saveConfiguration.UserName;
                    if (!string.IsNullOrWhiteSpace(saveConfiguration.Password))
                    {
                        t.Password = saveConfiguration.Password;
                    }
                }

                externalSettings.Settings = JObject.FromObject(t).ToString();
                externalSettings.IsComplete = true;
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = new
                {
                    Status = "success"
                }
            };
        }

        [HttpGet]
        [Route("status")]
        public async Task<dynamic> TestConnectivity()
        {
            using (var r = await _integrationServerClient.GetResponse($"api/exchange/status/{_context.User.Id}"))
            {
                r.EnsureSuccessStatusCode();
                return new
                {
                    Result = bool.Parse(await r.Content.ReadAsStringAsync())
                };
            }
        }
    }
}