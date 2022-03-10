using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Work
{
    public interface IBillingCapCheck
    {
        Task<dynamic> ForCase(int caseId, DateTime transactionDate);
        Task<dynamic> ForName(int nameId, DateTime transactionDate);
    }

    public class BillingCapCheck : IBillingCapCheck
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;
        readonly Func<DateTime> _now;
        readonly IDisplayFormattedName _displayFormattedName;

        public BillingCapCheck(IDbContext dbContext, ISiteControlReader siteControlReader, Func<DateTime> now, IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _now = now;
            _displayFormattedName = displayFormattedName;
        }

        public async Task<dynamic> ForCase(int caseId, DateTime transactionDate)
        {
            var today = _now();
            var debtors = _dbContext.Set<CaseName>()
                                       .Where(cn => cn.Case.Id == caseId &&
                                                    cn.NameType.NameTypeCode == KnownNameTypes.Debtor &&
                                                    (!cn.ExpiryDate.HasValue || cn.ExpiryDate > today));
            var billingCap = (from i in _dbContext.Set<ClientDetail>()
                             join c in debtors on i.Id equals c.NameId
                             where i.BillingCap != null && i.BillingCap.Value > 0
                             select new BillingCapData
                             {
                                 Value = i.BillingCap,
                                 Period = i.BillingCapPeriod,
                                 PeriodType = i.BillingCapPeriodType,
                                 StartDate = i.BillingCapStartDate,
                                 IsRecurring = i.IsBillingCapRecurring,
                                 DebtorId = i.Id
                             }).ToArray();

            var result = new List<BillingCapData>();
            foreach (var billingCapData in billingCap)
            {
                var data = await BillingCapCheckResult(billingCapData, transactionDate);
                if (data != null)
                    result.Add(data);
            }   

            if (!result.Any())
                return null;

            var formattedNames = await _displayFormattedName.For(result.Select(_ => _.DebtorId.GetValueOrDefault()).ToArray());
            foreach (var billingCapResult in result) 
                billingCapResult.DebtorName = formattedNames[billingCapResult.DebtorId.GetValueOrDefault()].Name;

            return result;
        }

        public async Task<dynamic> ForName(int nameId, DateTime transactionDate)
        {
            var billingCap = (from i in _dbContext.Set<ClientDetail>()
                              join n in _dbContext.Set<Name>().Where(_ => _.Id == nameId) on i.Id equals n.Id
                              where i.BillingCap != null && i.BillingCap.Value > 0
                              select new BillingCapData
                              {
                                  Value = i.BillingCap,
                                  Period = i.BillingCapPeriod,
                                  PeriodType = i.BillingCapPeriodType,
                                  StartDate = i.BillingCapStartDate,
                                  IsRecurring = i.IsBillingCapRecurring,
                                  DebtorId = nameId
                              }).SingleOrDefault();

            return await BillingCapCheckResult(billingCap, transactionDate);
        }

        async Task<dynamic> BillingCapCheckResult(BillingCapData billingCap, DateTime transactionDate)
        {
            if (billingCap?.Value == null || billingCap.Value == 0)
                return null;

            var capDate = GetStartDate(transactionDate, billingCap, out DateTime capStartDate);
            if (capDate < transactionDate)
                return null;

            var totalBilled = await (from i in _dbContext.Set<OpenItem>()
                                                         .Where(_ => _.Status == TransactionStatus.Active &&
                                                                     _.TypeId == ItemType.DebitNote &&
                                                                     _.AccountDebtorId == billingCap.DebtorId &&
                                                                     _.PostDate >= capStartDate)
                                     join c in _dbContext.Set<OpenItemCase>()
                                                         .Where(_ => _.Status == TransactionStatus.Draft || 
                                                                     _.Status == TransactionStatus.Active || 
                                                                     _.Status == TransactionStatus.Locked || 
                                                                     _.Status == TransactionStatus.Reversed) 
                                         on new {x1 = i.ItemEntityId, x2 = i.ItemTransactionId, x3 = i.AccountEntityId, x4 = i.AccountDebtorId} 
                                         equals new {x1 = c.ItemEntityId, x2 = c.ItemTransactionId, x3 = c.AccountEntityId, x4 = c.AccountDebtorId} into ci
                                     from cix in ci.DefaultIfEmpty()
                                     select cix != null ? cix.LocalValue : i.LocalValue ?? (decimal?)0)
                .SumAsync();

            var billingCapThreshold = _siteControlReader.Read<int?>(SiteControls.BillingCapThresholdPercent) ?? 0;
            if (billingCap.Value - billingCap.Value * ((decimal) billingCapThreshold / 100) < totalBilled)
            {
                return new BillingCapData
                {
                    Value = billingCap.Value,
                    Period = billingCap.Period,
                    PeriodType = billingCap.PeriodType,
                    StartDate = billingCap.StartDate,
                    IsRecurring = billingCap.IsRecurring,
                    TotalBilled = totalBilled,
                    DebtorId = billingCap.DebtorId
                };
            }

            return null;
        }

        static DateTime GetStartDate(DateTime transactionDate, BillingCapData billingCap, out DateTime capStartDate)
        {
            var period = billingCap.Period.GetValueOrDefault();
            var capDate = billingCap.StartDate.GetValueOrDefault();

            if (!billingCap.IsRecurring.GetValueOrDefault())
            {
                capStartDate = capDate;
                return GetCapDate(capDate, billingCap.PeriodType, period);
            }   

            var periodDate = capDate;
            while (periodDate < transactionDate)
            {
                capDate = periodDate;
                periodDate = GetCapDate(periodDate, billingCap.PeriodType, period);
            }

            capStartDate = capDate;
            return periodDate;
        }

        static DateTime GetCapDate(DateTime periodDate, string periodType, int period)
        {
            switch (periodType)
            {
                case KnownPeriodTypes.Days:
                    periodDate = periodDate.AddDays(period);
                    break;
                case KnownPeriodTypes.Weeks:
                    periodDate = periodDate.AddDays(period * 7);
                    break;
                case KnownPeriodTypes.Months:
                    periodDate = periodDate.AddMonths(period);
                    break;
                case KnownPeriodTypes.Years:
                    periodDate = periodDate.AddYears(period);
                    break;
            }

            return periodDate;
        }

        public class BillingCapData
        {
            public decimal? Value { get; set; }
            public int? Period { get; set; }
            public string PeriodType { get; set; }
            public DateTime? StartDate { get; set; }
            public bool? IsRecurring { get; set; }
            public int? DebtorId { get; set; }
            public string DebtorName { get; set; }
            public decimal? TotalBilled { get; set; }
        }
    }
}
