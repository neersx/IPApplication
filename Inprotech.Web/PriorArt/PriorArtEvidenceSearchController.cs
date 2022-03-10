using System;
using System.IdentityModel.Protocols.WSTrust;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Analytics;
using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class PriorArtEvidenceSearchController : ApiController
    {
        readonly IConcurrentPriorArtEvidenceFinder _concurrentPriorArtEvidenceArtEvidenceFinder;
        readonly IIpPlatformSession _ipPlatformSession;
        readonly IBus _bus;

        public PriorArtEvidenceSearchController(
            IConcurrentPriorArtEvidenceFinder concurrentPriorArtEvidenceArtEvidenceFinder,
            IIpPlatformSession ipPlatformSession, IBus bus)
        {
            _concurrentPriorArtEvidenceArtEvidenceFinder = concurrentPriorArtEvidenceArtEvidenceFinder;
            _ipPlatformSession = ipPlatformSession;
            _bus = bus;
        }

        [HttpPost]
        [Route("api/priorart/evidencesearch")]
        public async Task<SearchResult[]> Index(SearchRequest args)
        {
            if (args == null) throw new ArgumentNullException(nameof(args));
            if (args.SourceType == PriorArtTypes.Ipo && args.IpoSearchType == IpoSearchType.Single && (string.IsNullOrWhiteSpace(args.OfficialNumber) || string.IsNullOrWhiteSpace(args.Country))) throw new InvalidRequestException();
            if (args.SourceType == PriorArtTypes.Ipo && args.IpoSearchType == IpoSearchType.Multiple && !args.MultipleIpoSearch.Any()) throw new InvalidRequestException();

            var options = new SearchResultOptions
            {
                ReferenceHandling =
                {
                    IsIpPlatformSession = _ipPlatformSession.IsActive(Request)
                }
            };
            await _bus.PublishAsync(new TransactionalAnalyticsMessage
            {
                EventType = TransactionalEventTypes.PriorArtSearch,
                Value = TransactionalEventTypes.PriorArtSearch
            });

            var tasks = _concurrentPriorArtEvidenceArtEvidenceFinder.Find(args, options).ToArray();
            Task.WaitAll(tasks);
            return tasks.Select(t => t.Result).ToArray();
        }
    }
}