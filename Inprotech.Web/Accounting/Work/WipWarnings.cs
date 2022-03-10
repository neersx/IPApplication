using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Work
{
    public interface IWipWarnings
    {
        Task<bool> AllowWipFor(int caseId);
        Task<bool> HasDebtorRestriction(int caseId);
        Task<bool> HasNameRestriction(int nameId);
    }

    public class WipWarnings : IWipWarnings
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ISiteControlReader _siteControl;

        public WipWarnings(IDbContext dbContext, Func<DateTime> now, ISiteControlReader siteControl)
        {
            _dbContext = dbContext;
            _now = now;
            _siteControl = siteControl;
        }

        public async Task<bool> AllowWipFor(int caseId)
        {
            var result = await _dbContext.Set<Case>().AsNoTracking().SingleOrDefaultAsync(_ => _.Id == caseId && (_.CaseStatus == null || _.CaseStatus.PreventWip != true));
            return result != null;
        }

        public async Task<bool> HasDebtorRestriction(int caseId)
        {
            var now = _now();
            if (!_siteControl.Read<bool>(SiteControls.RestrictOnWIP))
                return false;

            var result = await (from cn in _dbContext.Set<CaseName>()
                          join nt in _dbContext.Set<NameType>() on cn.NameType equals nt
                          join cl in _dbContext.Set<ClientDetail>() on cn.NameId equals cl.Id
                          where cn.CaseId == caseId && nt.IsNameRestricted == 1 && (cn.StartingDate == null || cn.StartingDate <= now.Date) &&
                                (cn.ExpiryDate == null || cn.ExpiryDate > now.Date)
                          select cl.DebtorStatus).AsNoTracking().ToArrayAsync();
            return result.Any(_ => _?.RestrictionAction == KnownDebtorRestrictions.DisplayError);
        }

        public async Task<bool> HasNameRestriction(int nameId)
        {
            if (!_siteControl.Read<bool>(SiteControls.RestrictOnWIP))
                return false;

            var result = await (from cl in _dbContext.Set<ClientDetail>()
                                where cl.Id == nameId
                                select cl.DebtorStatus).AsNoTracking().ToArrayAsync();
            return result.Any(_ => _?.RestrictionAction == KnownDebtorRestrictions.DisplayError);
        }

    }
}