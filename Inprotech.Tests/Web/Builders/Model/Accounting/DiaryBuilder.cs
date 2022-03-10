using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    public class DiaryBuilder : IBuilder<Diary>
    {
        readonly InMemoryDbContext _db;

        public DiaryBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public Case Case { get; set; }
        public WipTemplate Activity { get; set; }
        public Name Debtor { get; set; }
        public Name Instructor { get; set; }
        public Narrative Narrative { get; set; }
        public int? StaffId { get; set; }
        public int? EntityId { get; set; }
        public int? TransNo { get; set; }
        public int? EntryNo { get; set; }

        public int? ParentEntryNo { get; set; }
        public short? NarrativeNo { get; set; }
        public string NarrativeText { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? FinishTime { get; set; }
        public TimeSpan? TimeCarriedForward { get; set; }
        public decimal? TimeValue { get; set; }
        public short? TotalUnits { get; set; }
        public short? UnitsPerHour { get; set; }
        public bool? IsTimer { get; set; }
        public string LongNarrativeText { get; set; }

        public Diary Build()
        {
            var staffId = StaffId ?? Fixture.Integer();
            var today = Fixture.Today();
            var activity = Activity ?? new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(_db);
            var debtor = Debtor ?? new NameBuilder(_db).Build().In(_db);
            var diary = new Diary
            {
                StartTime = StartTime ?? today.AddHours(8),
                FinishTime = FinishTime ?? today.AddHours(8).AddMinutes(30),
                TotalTime = StartTime.HasValue && FinishTime.HasValue ? DateTime.MinValue.Add(FinishTime.Value - StartTime.Value) : DateTime.MinValue.AddMinutes(30),
                NameNo = debtor.Id,
                Name = debtor,
                ActivityDetail = activity,
                Activity = activity.WipCode,
                ShortNarrative = Narrative == null ? NarrativeText ?? Fixture.String() : null,
                Notes = Fixture.String(),
                EmployeeNo = staffId,
                TimeValue = TimeValue ?? 30,
                EntryNo = EntryNo.GetValueOrDefault(),
                ParentEntryNo = ParentEntryNo,
                IsTimer = IsTimer.GetValueOrDefault() ? 1 : 0,
                NarrativeNo = NarrativeNo,
                WipEntityId = EntityId,
                TransactionId = TransNo,
                Narrative = Narrative,
                LongNarrative = Narrative == null ? LongNarrativeText : null,
                DebtorSplits = new List<DebtorSplitDiary>()
            }.In(_db);
            return diary;
        }

        public Diary BuildWithCase(bool withValues = false, bool asHoursOnlyTime = false)
        {
            var staffId = StaffId ?? Fixture.Integer();
            var today = Fixture.Today();
            var activity = Activity ?? new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(_db);
            var @case = Case ?? new CaseBuilder().Build().In(_db);
            var instructorNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Instructor}.Build().In(_db);
            var name = Instructor ?? new NameBuilder(_db).Build().In(_db);
            if (Case != null && Case.CaseNames.All(_ => _.NameTypeId != KnownNameTypes.Instructor) || Case == null)
            {
                new CaseNameBuilder(_db) {NameType = instructorNameType, Name = name, Sequence = 0}.BuildWithCase(@case).In(_db);
            }
            
            new CaseNameBuilder(_db) {Name = name}.BuildWithCase(@case).In(_db);
            var diary = new Diary
            {
                StartTime = StartTime ?? today.AddHours(8),
                FinishTime = FinishTime ?? today.AddHours(8).AddMinutes(30),
                TotalTime = asHoursOnlyTime ? DateTime.MinValue.AddMinutes(30) : StartTime.HasValue && FinishTime.HasValue ? DateTime.MinValue.Add(FinishTime.Value - StartTime.Value) : DateTime.MinValue.AddMinutes(30),
                Case = @case,
                CaseId = @case.Id,
                ActivityDetail = activity,
                Activity = activity.WipCode,
                ShortNarrative = NarrativeText ?? Fixture.String(),
                Notes = Fixture.String(),
                EmployeeNo = staffId,
                TransactionId = TransNo,
                WipEntityId = EntityId,
                EntryNo = EntryNo.GetValueOrDefault(),
                ParentEntryNo = ParentEntryNo,
                TimeCarriedForward = TimeCarriedForward != null ? new DateTime(1899, 1, 1).AddSeconds(TimeCarriedForward.GetValueOrDefault().TotalSeconds) : (DateTime?) null,
                IsTimer = IsTimer.GetValueOrDefault() ? 1 : 0,
                NarrativeNo = NarrativeNo,
                DebtorSplits = new List<DebtorSplitDiary>()
            };

            if (!withValues) return diary.In(_db);

            diary.TimeValue = TimeValue ?? Fixture.Decimal();
            diary.ForeignValue = Fixture.Decimal();
            diary.DiscountValue = Fixture.Decimal();
            diary.ForeignDiscount = Fixture.Decimal();
            diary.TotalUnits = TotalUnits ?? Fixture.Short();
            diary.ForeignCurrency = Fixture.RandomString(3);
            diary.CostCalculation1 = Fixture.Decimal();
            diary.CostCalculation2 = Fixture.Decimal();
            diary.ChargeOutRate = Fixture.Decimal();
            diary.ExchRate = Fixture.Decimal();
            diary.UnitsPerHour = UnitsPerHour ?? Fixture.Short();
            return diary.In(_db);
        }
    }
}