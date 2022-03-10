using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders.Accounting
{
    internal class DiaryBuilder : Builder
    {
        public DiaryBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public Diary Create(int? staffId,
                            int entryNo,
                            DateTime dateTime,
                            int? caseId,
                            int? nameId,
                            string activity,
                            string narrative = null,
                            string notes = null,
                            string currency = null,
                            decimal? localValue = null,
                            decimal? rate = null,
                            decimal? localDiscount = null,
                            bool isPosted = false,
                            int? parentEntryNo = null,
                            bool isContinuedParent = false,
                            bool isHoursOnly = false)
        {
            var start = dateTime;
            var narr = narrative ?? RandomString.Next(40);
            var diary = new Diary
            {
                EmployeeNo = staffId.GetValueOrDefault(),
                EntryNo = entryNo,
                StartTime = start,
                FinishTime = isHoursOnly ? (DateTime?) start : start.AddHours(1),
                UnitsPerHour = 10,
                TotalUnits = 10,
                ChargeOutRate = rate ?? (decimal) 300.00,
                Activity = activity,
                CaseId = caseId,
                NameNo = nameId,
                ShortNarrative = narr.Length <= 254 ? narr : null,
                LongNarrative = narr.Length > 254 ? narr : null,
                Notes = notes,
                ForeignCurrency = currency,
                CreatedOn = DateTime.Now,
                TimeValue = localValue.GetValueOrDefault(),
                ForeignValue = !string.IsNullOrWhiteSpace(currency) ? localValue.GetValueOrDefault() * (decimal) 1.5 : (decimal?) null,
                DiscountValue = localDiscount.GetValueOrDefault(),
                ForeignDiscount = !string.IsNullOrWhiteSpace(currency) ? localDiscount.GetValueOrDefault() * (decimal) 1.5 : (decimal?) null,
                WipEntityId = isPosted ? (int?) Fixture.Integer() : null,
                TransactionId = isPosted ? (int?) Fixture.Integer() : null,
                ParentEntryNo = parentEntryNo,
                TimeCarriedForward = parentEntryNo.HasValue ? new DateTime(1899, 01, 01).AddHours(1) : (DateTime?) null
            };
            if (!isContinuedParent) diary.TotalTime = new DateTime(1899, 01, 01).AddHours(1);
            return Insert(diary);
        }
    }
}