using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Innography.PrivatePair;

namespace Inprotech.Integration.Uspto.PrivatePair.Sponsorships
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ConfigureUsptoPractitionerSponsorship)]
    [NoEnrichment]
    [RoutePrefix("api/ptoaccess/uspto/privatepair/sponsorships")]
    public class SponsorshipController : ApiController
    {
        readonly ISponsorshipProcessor _sponsorshipProcessor;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IInnographyPrivatePairSettings _innographyPrivatePairSettings;
        readonly Func<HostInfo> _hostInfoResolver;
        readonly ISiteControlReader _siteControlReader;

        public SponsorshipController(
            ISponsorshipProcessor sponsorshipProcessor,
            ITaskSecurityProvider taskSecurityProvider,
            IInnographyPrivatePairSettings innographyPrivatePairSettings,
            Func<HostInfo> hostInfoResolver,
            ISiteControlReader siteControlReader)
        {
            _sponsorshipProcessor = sponsorshipProcessor;
            _taskSecurityProvider = taskSecurityProvider;
            _innographyPrivatePairSettings = innographyPrivatePairSettings;
            _hostInfoResolver = hostInfoResolver;
            _siteControlReader = siteControlReader;
        }

        [HttpPost]
        [Route("")]
        public async Task<ExecutionResult> Post(SponsorshipModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var result = await _sponsorshipProcessor.CreateSponsorship(request);

            return result;
        }

        [HttpGet]
        [Route("")]
        public async Task<dynamic> Get()
        {
            var canScheduleDataDownload = _taskSecurityProvider.HasAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload);
            var settings = _innographyPrivatePairSettings.Resolve();
            var sponsorships = (await _sponsorshipProcessor.GetSponsorships()).ToArray();
            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            var envInvalid = sponsorships.Any() && !string.Equals(settings.ValidEnvironment, dbIdentifier, StringComparison.CurrentCultureIgnoreCase);
            var missingBackgroundProcessLoginId = string.IsNullOrWhiteSpace(_siteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId));

            return new
            {
                CanScheduleDataDownload = canScheduleDataDownload,
                ClientId = settings.PrivatePairSettings.IsAccountSettingsValid ? settings.PrivatePairSettings.ClientId : string.Empty,
                envInvalid,
                missingBackgroundProcessLoginId,
                sponsorships
            };
        }

        [HttpPatch]
        [Route("")]
        public async Task<ExecutionResult> Update(SponsorshipModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var result = await _sponsorshipProcessor.UpdateSponsorship(request);

            return result;
        }

        [HttpDelete]
        [Route("{id}")]
        public async Task<dynamic> Delete(int id)
        {
            await _sponsorshipProcessor.DeleteSponsorship(id);

            return new { Result = "success" };
        }

        [HttpPatch]
        [Route("accountSettings")]
        public async Task<ExecutionResult> UpdateOneTimeGlobalAccountSettings(UsptoAccountSettingsUpdateModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var result = await _sponsorshipProcessor.UpdateOneTimeGlobalAccountSettings(request.QueueUrl.Trim(), request.QueueId.Trim(), request.QueueSecret.Trim());

            return result;
        }

        public class UsptoAccountSettingsUpdateModel
        {
            public string QueueUrl { get; set; }
            public string QueueId { get; set; }
            public string QueueSecret { get; set; }
        }
    }
}