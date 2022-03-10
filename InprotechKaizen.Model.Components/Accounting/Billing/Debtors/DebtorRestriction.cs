using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Debtors
{
    public interface IDebtorRestriction
    {
        Task<Dictionary<int, DebtorRestrictionStatus>> GetDebtorRestriction(string culture, int[] debtorIds);

        Task<bool> HasDebtorsNotConfiguredForBilling(params int[] debtorIds);
    }
    public class DebtorRestriction : IDebtorRestriction
    {
        readonly IDbContext _dbContext;

        public DebtorRestriction(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<Dictionary<int, DebtorRestrictionStatus>> GetDebtorRestriction(string culture, params int[] debtorIds)
        {
            var debtorData = from n in _dbContext.Set<Name>()
                              join ip in _dbContext.Set<ClientDetail>() on n.Id equals ip.Id into ip1
                              from ip in ip1.DefaultIfEmpty()
                              where debtorIds.Contains(n.Id)
                              select new DebtorRestrictionStatus
                              {
                                  NameId = n.Id,
                                  DebtorStatusAction = ip != null && ip.DebtorStatus != null
                                      ? ip.DebtorStatus.RestrictionType != null
                                          ? (short?)ip.DebtorStatus.RestrictionType : KnownDebtorRestrictions.NoRestriction
                                      : null,
                                  DebtorStatus = ip != null && ip.DebtorStatus != null
                                      ? DbFuncs.GetTranslation(ip.DebtorStatus.Status, null, ip.DebtorStatus.StatusTId, culture)
                                      : null
                              };

            return await debtorData.ToDictionaryAsync(x => x.NameId, y => y );
        }

        public async Task<bool> HasDebtorsNotConfiguredForBilling(params int[] debtorIds)
        {
            var distinctDebtorIds = debtorIds.Distinct();
            
            return await _dbContext.Set<ClientDetail>()
                                   .CountAsync(_ => distinctDebtorIds.Contains(_.Id)) != distinctDebtorIds.Count();
        }
    }

    public class DebtorRestrictionStatus
    {
        public int NameId { get; set; }
        public string DebtorStatus { get; set; }
        public short? DebtorStatusAction { get; set; }
    }
}