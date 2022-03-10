using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Work
{
    public interface IBudgetWarnings
    {
        Task<dynamic> For(int caseId, DateTime selectedDate);
    }

    public class BudgetWarnings : IBudgetWarnings
    {
        readonly IDbContext _dbContext;
        readonly IAccountingProvider _accountingProvider;
        readonly ISiteControlReader _siteControlReader;

        public BudgetWarnings(IDbContext dbContext, IAccountingProvider accountingProvider, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _accountingProvider = accountingProvider;
            _siteControlReader = siteControlReader;
        }

        public async Task<dynamic> For(int caseId, DateTime selectedDate)
        {
            var budget = await _dbContext.Set<Case>().Where(_ => _.Id == caseId)
                                         .Select(_ => new
                                         {
                                             Revised = _.BudgetRevisedAmt,
                                             Original = _.BudgetAmount,
                                             Start = _.BudgetStartDate,
                                             End = _.BudgetEndDate
                                         }).SingleAsync();
            if ((!budget.Revised.HasValue && !budget.Original.HasValue) || (budget.Start.HasValue && budget.Start.Value > selectedDate) || (budget.End.HasValue && budget.End.Value < selectedDate))
                return null;

            var allMovementClasses = new[]
            {
                MovementClass.Entered, 
                MovementClass.Billed, 
                MovementClass.AdjustUp, 
                MovementClass.AdjustDown
            };

            var workHistoryList = await (from h in _dbContext.Set<WorkHistory>()
                                         where h.CaseId == caseId && h.Status != (int) TransactionStatus.Draft && h.MovementClass != null && allMovementClasses.Contains(h.MovementClass.Value)
                                         select new WorkHistoryItem
                                         {
                                             LocalValue = h.LocalValue,
                                             MovementClass = (short?) h.MovementClass, 
                                             EntityNo = h.EntityId,
                                             TransNo = h.TransactionId,
                                             WipSeqNo = h.WipSequenceNo,
                                             TransDate = h.TransDate
                                         }).ToArrayAsync();

            if (workHistoryList.All(_ => _.MovementClass == (short) MovementClass.Billed))
                return null;

            var usedTotal = workHistoryList.Where(_ => _.MovementClass != (short) MovementClass.Billed && (budget.Start == null || _.TransDate >= budget.Start) && (budget.End == null || _.TransDate <= budget.End))
                                           .Select(_ => _.LocalValue ?? 0)
                                           .Sum();

            var maxPercentageUsed = _siteControlReader.Read<int?>(SiteControls.BudgetPercentageUsed);
            var budgetPercentageUsed = Math.Round(usedTotal * 100 / (decimal) (budget.Revised ?? budget.Original), 2);

            if (maxPercentageUsed.HasValue && budgetPercentageUsed <= maxPercentageUsed)
                return null;

            if ((!maxPercentageUsed.HasValue || !(budgetPercentageUsed > maxPercentageUsed)) && !(usedTotal > (budget.Revised ?? budget.Original))) 
                return null;
            
            decimal billedWipTotal;
            if (!budget.Start.HasValue && !budget.End.HasValue)
            {
                billedWipTotal = workHistoryList.Where(_ => _.MovementClass == (short) MovementClass.Billed)
                                                .Select(_ => _.LocalValue ?? 0)
                                                .Sum();
            }
            else
            {
                var billedStuff = from b in workHistoryList.Where(_ => _.MovementClass == (short) MovementClass.Billed)
                                  join bw in workHistoryList.Where(_ => _.MovementClass != (short) MovementClass.Billed)
                                      on new {b.EntityNo, b.TransNo, b.WipSeqNo} equals new {bw.EntityNo, bw.TransNo, bw.WipSeqNo} into billedWip
                                  from bi in billedWip.DefaultIfEmpty(new WorkHistoryItem())
                                  where bi.TransDate == null && (budget.Start == null || b.TransDate >= budget.Start) && (budget.End == null || b.TransDate <= budget.End) ||
                                        (budget.Start == null || bi.TransDate >= budget.Start) && (budget.End == null || bi.TransDate <= budget.End)
                                  select b.LocalValue ?? 0;

                billedWipTotal = billedStuff.Sum();
            }
            return new
            {
                budget,
                billedTotal = billedWipTotal * -1,
                usedTotal,
                unbilledTotal = usedTotal > (budget.Revised ?? budget.Original) ? await _accountingProvider.UnbilledWipFor(caseId, budget.Start, budget.End) : 0,
                PercentageUsed = Math.Round(usedTotal * 100 / (decimal) (budget.Revised ?? budget.Original), 2)
            };
        }

        class WorkHistoryItem
        {
            public decimal? LocalValue { get; set; }
            public short? MovementClass { get; set; }
            public int? EntityNo { get; set; }
            public int? TransNo { get; set; }
            public short? WipSeqNo { get; set; }
            public DateTime? TransDate { get; set; }
        }
    }
}