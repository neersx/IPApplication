using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class WipDebtorSelector : IWipDebtorSelector
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public WipDebtorSelector(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public IQueryable<Debtor> GetDebtorsForCaseWip(int caseId, string activityKey)
        {
            var nameType = GetDebtorNameTypeForWip(caseId, activityKey);
            return DebtorsForCase(caseId, nameType);
        }

        public async Task<(bool IsMultiDebtorWip, bool IsRenewalWip)> CaseActivityMultiDebtorStatus(int caseId, string activityKey)
        {
            if (!_siteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor))
                return (false, false);

            var nameType = GetDebtorNameTypeForWip(caseId, activityKey);

            var hasMultiple = await DebtorsForCase(caseId, nameType).CountAsync() > 1;
            var isRenewalWip = nameType == KnownNameTypes.RenewalsDebtor;

            return (IsMultiDebtorWip: hasMultiple, isRenewalWip);
        }

        IQueryable<Debtor> DebtorsForCase(int caseId, string nameType)
        {
            var caseNames = _dbContext.Set<CaseName>().Where(cn => cn.CaseId == caseId
                                                                   && cn.NameTypeId == nameType);
            var nameIds = from cn in caseNames
                          select cn.NameId;

            var clientDetails = _dbContext.Set<ClientDetail>().Where(cd => nameIds.Contains(cd.Id));

            return from cn in caseNames
                   from cd in clientDetails
                   where cd.Id == cn.NameId
                   select new Debtor
                   {
                       CaseId = cn.CaseId,
                       NameId = cd.Id,
                       BillingPercentage = cn.BillingPercentage,
                       SeparateMarginFlag = cd.UseSeparateMargin,
                       NameType = nameType
                   };
        }

        string GetDebtorNameTypeForWip(int caseId, string activityKey)
        {
            if (!_siteControlReader.Read<bool>(SiteControls.BillRenewalDebtor) &&
                Convert.ToInt16(_dbContext.Set<WipTemplate>()
                                          .Where(wt => wt.WipCode == activityKey)
                                          .Select(wt => wt.IsRenewalWip).FirstOrDefault()) == 1 &&
                CaseHasRenewalDebtors(caseId))
            {
                return KnownNameTypes.RenewalsDebtor;
            }

            return KnownNameTypes.Debtor;
        }

        bool CaseHasRenewalDebtors(int caseId)
        {
            return _dbContext.Set<CaseName>().Any(cn => cn.CaseId == caseId
                                                        && cn.NameTypeId == KnownNameTypes.RenewalsDebtor);
        }
    }

    public interface IWipDebtorSelector
    {
        IQueryable<Debtor> GetDebtorsForCaseWip(int caseId, string activityKey);

        Task<(bool IsMultiDebtorWip, bool IsRenewalWip)> CaseActivityMultiDebtorStatus(int caseId, string activityKey);
    }

    public class Debtor
    {
        public int CaseId { get; set; }
        public int NameId { get; set; }
        public decimal? BillingPercentage { get; set; }
        public bool? SeparateMarginFlag { get; set; }
        public string NameType { get; set; }
        public BestNarrative DefaultNarrative { get; set; }
    }
}