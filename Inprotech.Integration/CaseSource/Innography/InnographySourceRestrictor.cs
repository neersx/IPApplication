using System.Linq;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.CaseSource.Innography
{
    public class InnographySourceRestrictor : ISourceRestrictor
    {
        readonly IDbContext _dbContext;
        readonly IInnographyPatentsRestrictor _patentsRestrictor;
        readonly IInnographyTrademarksRestrictor _trademarksRestrictor;

        public InnographySourceRestrictor(IDbContext dbContext,
                                            IInnographyPatentsRestrictor patentsRestrictor,
                                            IInnographyTrademarksRestrictor trademarksRestrictor)
        {
            _dbContext = dbContext;
            _patentsRestrictor = patentsRestrictor;
            _trademarksRestrictor = trademarksRestrictor;
        }

        public IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, DownloadType downloadType = DownloadType.All)
        {
            return downloadType == DownloadType.OngoingVerification ? RestrictForOngoing(cases) : RestrictForMatching(cases);
        }

        IQueryable<EligibleCaseItem> RestrictForMatching(IQueryable<EligibleCaseItem> cases)
        {
            var casesLinked = _dbContext.Set<CpaGlobalIdentifier>().AsQueryable();

            var systemCode = ExternalSystems.SystemCode(DataSourceType.IpOneData);

            return _patentsRestrictor.Restrict(cases, systemCode)
                                     .Concat(_trademarksRestrictor.Restrict(cases, systemCode))
                                     .Where(elc => elc.IsLiveCase && !casesLinked.Any(_ => _.CaseId == elc.CaseKey));
        }

        IQueryable<EligibleCaseItem> RestrictForOngoing(IQueryable<EligibleCaseItem> cases)
        {
            var casesLinked = _dbContext.Set<CpaGlobalIdentifier>();

            return from c in cases
                   where casesLinked.Any(_ => _.CaseId == c.CaseKey)
                   select c;
        }
    }
}