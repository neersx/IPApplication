using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface ICurrentNames
    {
        IEnumerable<CaseName> For(Case @case);
        IQueryable<CaseName> For(int caseId, params string[] nameTypeKeys);
    }

    public class CurrentNames : ICurrentNames
    {
        readonly Func<DateTime> _now;
        readonly IDbContext _dbContext;

        public CurrentNames(Func<DateTime> now, IDbContext dbContext)
        {
            _now = now;
            _dbContext = dbContext;
        }

        public IEnumerable<CaseName> For(Case @case)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            return @case.CaseNames.Where(IsActive);
        }

        public IQueryable<CaseName> For(int caseId, params string[] nameTypeKeys)
        {
            var today = _now().Date;

            var all = from cn in _dbContext.Set<CaseName>()
                   where cn.CaseId == caseId
                         && (cn.StartingDate == null || cn.StartingDate <= today)
                         && (cn.ExpiryDate == null || cn.ExpiryDate > today)
                   select cn;

            return nameTypeKeys.Any()
                ? all.Where(_ => nameTypeKeys.Contains(_.NameTypeId))
                : all;
        }

        bool IsActive(CaseName caseName)
        {
            if (!caseName.Name.IsActive(_now))
                return false;
            
            var today = _now().Date;

            return (caseName.StartingDate == null || caseName.StartingDate <= today) &&
                   (caseName.ExpiryDate == null || caseName.ExpiryDate > today);
        }
    }
}
