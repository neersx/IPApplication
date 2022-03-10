using System.Linq;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

namespace Inprotech.IntegrationServer.PtoAccess.Recovery
{
    public class CaseResolverProvider : IProvideCaseResolvers
    {
        readonly IRepository _repository;
        readonly CasesForDownloadResolver _casesResolver;
        readonly RecoveryCasesForDownloadResolver _recoveryCasesResolver;

        public CaseResolverProvider(IRepository repository, CasesForDownloadResolver casesResolver,
            RecoveryCasesForDownloadResolver recoveryCasesResolver)
        {
            _repository = repository;
            _casesResolver = casesResolver;
            _recoveryCasesResolver = recoveryCasesResolver;
        }

        public IResolveCasesForDownload Get(DataDownload session)
        {
            var scheduleType =
                _repository.Set<Schedule>().Where(s => s.Id == session.ScheduleId).Select(s => s.Type).Single();

            switch (scheduleType)
            {
                case ScheduleType.Retry:
                    return _recoveryCasesResolver;
                default:
                    return _casesResolver;
            }
        }
    }
}