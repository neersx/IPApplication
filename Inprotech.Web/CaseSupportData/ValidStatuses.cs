using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.CaseSupportData
{
    public interface IValidStatuses
    {
        IEnumerable<ValidStatusListItem> All(int identityId, string culture, bool? isRenewal);
    }

    public class ValidStatuses : IValidStatuses
    {
        readonly IDbContext _dbContext;

        public ValidStatuses(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<ValidStatusListItem> All(int identityId, string culture, bool? isRenewal)
        {
            var statuses = _dbContext.GetValidStatuses(identityId, culture, isRenewal).ToArray();

            var statusIds = statuses.Select(_ => _.StatusKey).ToArray();

            var actual = _dbContext.Set<Status>().Where(_ => statusIds.Contains(_.Id)).ToDictionary(k => k.Id, v => v);

            foreach (var s in statuses)
            {
                var a = actual[s.StatusKey];

                s.IsRenewal = a.IsRenewal;
                s.IsDead = !a.IsLive;
                s.IsRegistered = a.IsRenewal;
                s.IsPending = a.IsLive && !a.IsRenewal;

                yield return s;
            }
        }
    }
}