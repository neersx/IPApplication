using System;
using System.Linq;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders.Accounting
{
    internal class WipBuilder : Builder
    {
        public WipBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public TransactionType TransactionType { get; set; } = TransactionType.Timesheet;

        public WorkInProgress Build(int entityId, int? caseId, string wipCode, decimal? value)
        {
            var transNo = Fixture.Integer();
            var transDate = DateTime.Now;
            var today = transDate.Date;
            var tomorrow = today.AddDays(1);
            var postPeriod = DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => _.Id).FirstOrDefault();
            Insert(new TransactionHeader
            {
                EntityId = entityId,
                TransactionId = transNo,
                TransactionDate = transDate,
                EntryDate = transDate.AddDays(-1),
                TransactionType = TransactionType,
                UserLoginId = Fixture.String(20),
                PostPeriodId = postPeriod
            });

            return Insert(new WorkInProgress
            {
                EntityId = entityId,
                TransactionId = transNo,
                WipSequenceNo = 1,
                CaseId = caseId ?? Fixture.Integer(),
                WipCode = wipCode,
                LocalValue = value ?? Fixture.Short(10000),
                Balance = value ?? Fixture.Short(10000),
                TransactionDate = transDate,
                Status = TransactionStatus.Active
            });
        }

        public (WorkInProgress Wip, WorkInProgress Discount, WorkInProgress Margin) BuildWithWorkHistory(int entityId, int? caseId, string wipCode, decimal? value, decimal? discountValue = null, string foreignCurrency = null, decimal? exchangeRate = null, TransactionStatus wipStatus = TransactionStatus.Active)
        {
            return BuildWithWorkHistoryCommon(entityId, caseId ?? Fixture.Integer(), null, wipCode, value, discountValue, foreignCurrency, exchangeRate, wipStatus);
        }

        public (WorkInProgress Wip, WorkInProgress Discount, WorkInProgress Margin) BuildDebtorOnlyWithWorkHistory(int entityId, int debtorId, string wipCode, decimal? value, decimal? discountValue = null, string foreignCurrency = null, decimal? exchangeRate = null, TransactionStatus wipStatus = TransactionStatus.Active)
        {
            return BuildWithWorkHistoryCommon(entityId, null, debtorId, wipCode, value, discountValue, foreignCurrency, exchangeRate, wipStatus);
        }

        (WorkInProgress Wip, WorkInProgress Discount, WorkInProgress Margin) BuildWithWorkHistoryCommon(int entityId, int? caseId, int? debtorId, string wipCode, decimal? value, decimal? discountValue = null, string foreignCurrency = null, decimal? exchangeRate = null, TransactionStatus wipStatus = TransactionStatus.Active)
        {
            var transactionId = Fixture.Integer();
            var transDate = DateTime.Now;
            var today = transDate.Date;
            var tomorrow = today.AddDays(1);
            var postPeriodId = DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => _.Id).FirstOrDefault();

            Insert(new TransactionHeader
            {
                EntityId = entityId,
                TransactionId = transactionId,
                TransactionDate = transDate,
                EntryDate = transDate.AddDays(-1),
                Source = SystemIdentifier.TimeAndBilling,
                TransactionType = TransactionType,
                UserLoginId = Fixture.String(20),
                PostPeriodId = postPeriodId
            });

            exchangeRate = string.IsNullOrWhiteSpace(foreignCurrency)
                ? null
                : exchangeRate ?? (decimal?) Fixture.Short(10) * (decimal) 0.1 + 1;

            var desiredValue = value ?? Fixture.Short(10000);

            var wip = Insert(new WorkInProgress
            {
                EntityId = entityId,
                TransactionId = transactionId,
                WipSequenceNo = 1,
                CaseId = caseId,
                AccountEntityId = entityId,
                AccountClientId = debtorId,
                WipCode = wipCode,
                LocalValue = GetLocalValue(foreignCurrency, desiredValue, exchangeRate),
                ForeignValue = GetForeignValue(foreignCurrency, desiredValue),
                ForeignBalance = GetForeignValue(foreignCurrency, desiredValue),
                ForeignCurrency = foreignCurrency,
                ExchangeRate = exchangeRate,
                Balance = GetLocalValue(foreignCurrency, desiredValue, exchangeRate),
                TransactionDate = transDate.Date,
                PostDate = wipStatus == TransactionStatus.Draft
                    ? null
                    : transDate,
                Status = wipStatus /* default is FinalisedOrPosted, 
                                    * if locked on a bill - use TransactionStatus.Locked, WH will still be 'FinalisedOrPosted' */
            });

            Insert(new WorkHistory
            {
                EntityId = wip.EntityId,
                TransactionId = wip.TransactionId,
                WipSequenceNo = wip.WipSequenceNo,
                TransDate = wip.TransactionDate,
                PostDate = wip.PostDate,
                CaseId = wip.CaseId,
                StaffId = wip.StaffId,
                AccountClientId = wip.AccountClientId,
                AccountEntityId = wip.AccountEntityId,
                WipCode = wip.WipCode,
                LocalValue = wip.LocalValue,
                ForeignValue = wip.ForeignValue,
                ForeignCurrency = wip.ForeignCurrency,
                ExchangeRate = wip.ExchangeRate,
                RefEntityId = wip.EntityId,
                RefTransactionId = wip.TransactionId,
                Status = wipStatus == TransactionStatus.Draft
                    ? TransactionStatus.Draft
                    : TransactionStatus.Active,
                MovementClass = MovementClass.Entered,
                CommandId = CommandId.Generate,
                ItemImpact = ItemImpact.Created,
                PostPeriodId = postPeriodId
            });

            var discountWip = discountValue == null
                ? null
                : CreateDiscountWip();

            WorkInProgress CreateDiscountWip()
            {
                var d = Insert(new WorkInProgress
                {
                    EntityId = entityId,
                    TransactionId = transactionId,
                    WipSequenceNo = 2,
                    CaseId = wip.CaseId,
                    AccountClientId = wip.AccountClientId,
                    AccountEntityId = wip.AccountEntityId,
                    WipCode = "DISC",
                    NarrativeId = 1,
                    ShortNarrative = "Discount as agreed",
                    LocalValue = GetLocalValue(foreignCurrency, discountValue.Value, exchangeRate),
                    ForeignValue = GetForeignValue(foreignCurrency, discountValue.Value),
                    ForeignBalance = GetForeignValue(foreignCurrency, discountValue.Value),
                    ForeignCurrency = foreignCurrency,
                    Balance = GetLocalValue(foreignCurrency, discountValue.Value, exchangeRate),
                    TransactionDate = transDate.Date,
                    IsDiscount = 1,
                    PostDate = transDate,
                    Status = wipStatus == TransactionStatus.Draft
                        ? TransactionStatus.Draft
                        : TransactionStatus.Active
                });

                Insert(new WorkHistory
                {
                    EntityId = d.EntityId,
                    TransactionId = d.TransactionId,
                    WipSequenceNo = d.WipSequenceNo,
                    TransDate = d.TransactionDate,
                    PostDate = d.PostDate,
                    CaseId = d.CaseId,
                    StaffId = d.StaffId,
                    WipCode = d.WipCode,
                    LocalValue = d.LocalValue,
                    RefEntityId = d.EntityId,
                    RefTransactionId = d.TransactionId,
                    DiscountFlag = 1,
                    Status = wipStatus == TransactionStatus.Draft
                        ? TransactionStatus.Draft
                        : TransactionStatus.Active,
                    MovementClass = MovementClass.Entered,
                    CommandId = CommandId.Generate,
                    ItemImpact = ItemImpact.Created,
                    PostPeriodId = postPeriodId
                });

                return d;
            }

            return (wip, discountWip, null);
        }

        static decimal? GetLocalValue(string foreignCurrency, decimal value, decimal? exchangeRate)
        {
            if (string.IsNullOrWhiteSpace(foreignCurrency))
            {
                return value;
            }

            return Math.Round(value / exchangeRate.GetValueOrDefault(), 2);
        }

        static decimal? GetForeignValue(string foreignCurrency, decimal value)
        {
            if (string.IsNullOrWhiteSpace(foreignCurrency))
            {
                return null;
            }

            return value;
        }

        public WorkInProgress BuildDebtorOnlyWip(int entityId, int debtorNameId, string wipCode, decimal? value)
        {
            var transactionId = Fixture.Integer();
            var transDate = DateTime.Now;
            var today = transDate.Date;
            var tomorrow = today.AddDays(1);
            var postPeriod = DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => (int?) _.Id).FirstOrDefault();

            Insert(new TransactionHeader
            {
                EntityId = entityId,
                TransactionId = transactionId,
                TransactionDate = transDate,
                EntryDate = transDate.AddDays(-1),
                TransactionType = TransactionType.Timesheet,
                UserLoginId = Fixture.String(20),
                PostPeriodId = postPeriod
            });

            return Insert(new WorkInProgress
            {
                EntityId = entityId,
                TransactionId = transactionId,
                WipSequenceNo = 1,
                AccountClientId = debtorNameId,
                WipCode = wipCode,
                LocalValue = value ?? Fixture.Short(10000),
                Balance = value ?? Fixture.Short(10000),
                TransactionDate = transDate,
                Status = TransactionStatus.Active
            });
        }
    }
}