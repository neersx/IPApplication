using System;
using System.Linq;
using AutoMapper;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting
{
    public class AccountingProfile : Profile
    {
        public AccountingProfile()
        {
            string currentCulture = null;
            bool caseOnlyTime = false;
            bool isMultiDebtorEnabled = false;

            CreateMap<TimeEntry, RecordableTime>()
                .ForMember(d => d.Start, opt => opt.MapFrom(s => s.StartTime.GetValueOrDefault()))
                .ForMember(d => d.Finish, opt => opt.MapFrom(s => s.FinishTime.GetValueOrDefault()))
                .ForMember(d => d.EntryDate, opt => opt.MapFrom(s => s.StartTime.GetValueOrDefault().Date));

            CreateMap<RecordableTime, Diary>()
                .ForMember(d => d.EmployeeNo, opt => opt.MapFrom(s => s.StaffId))
                .ForMember(d => d.StartTime, opt => opt.MapFrom(s => s.Start ?? (DateTime?) s.EntryDate))
                .ForMember(d => d.FinishTime, opt => opt.MapFrom(s => s.Finish ?? (s.isTimer ? null : (DateTime?) s.EntryDate)))
                .ForMember(d => d.IsTimer, opt => opt.MapFrom(s => s.isTimer ? 1 : 0))
                .ForMember(d => d.CaseId, opt => opt.MapFrom(s => s.CaseKey))
                .ForMember(d => d.NameNo, opt =>
                {
                    opt.Condition(s => s.CaseKey == null);
                    opt.MapFrom(s => s.NameKey);
                })
                .ForMember(d => d.LongNarrative, opt => opt.MapFrom(s => s.NarrativeText != null && s.NarrativeText.Length > 254 ? s.NarrativeText : null))
                .ForMember(d => d.ShortNarrative, opt => opt.MapFrom(s => s.NarrativeText != null && s.NarrativeText.Length <= 254 ? s.NarrativeText : null))
                .ForMember(d => d.Notes, opt => opt.MapFrom(s => s.Notes != null ? s.Notes.Truncate(254) : null))
                .ForMember(d => d.TimeCarriedForward, opt => opt.Ignore())
                .ForMember(d => d.DebtorSplits, opt => opt.Ignore())
                .ReverseMap()
                .ForMember(d => d.EntryDate, opt => opt.MapFrom(s => s.StartTime.GetValueOrDefault().Date))
                .ForMember(d => d.NarrativeText, opt => opt.MapFrom(s => s.LongNarrative ?? s.ShortNarrative));

            CreateMap<WipCost, TimeEntry>()
                .ForMember(d => d.TotalUnits, opt => opt.MapFrom(s => s.TimeUnits))
                .ForMember(d => d.ForeignCurrency, opt => opt.MapFrom(s => s.CurrencyCode))
                .ForMember(d => d.TimeCarriedForward, opt => opt.Ignore());

            CreateMap<WipCost, TimeCost>()
                .ForMember(d => d.LocalMargin, opt => opt.MapFrom(s => s.LocalValue - s.LocalValueBeforeMargin))
                .ForMember(d => d.ForeignMargin, opt => opt.MapFrom(s => s.ForeignValue - s.ForeignValueBeforeMargin));

            CreateMap<TimeGap, RecordableTime>()
                .ForMember(d => d.Start, opt => opt.MapFrom(s => (DateTime?) DateTime.SpecifyKind(s.StartTime, DateTimeKind.Local)))
                .ForMember(d => d.Finish, opt => opt.MapFrom(s => (DateTime?) DateTime.SpecifyKind(s.FinishTime, DateTimeKind.Local)))
                .ForMember(d => d.TotalTime, opt => opt.MapFrom(s => s.Duration));

            CreateMap<Diary, TimeEntry>()
                .ForMember(d => d.CaseKey, opt => opt.MapFrom(s => s.Case == null ? null : (int?) s.Case.Id))
                .ForMember(d => d.Name, opt => opt.Ignore())
                .ForMember(d => d.Activity, opt => opt.MapFrom(s => s.ActivityDetail != null ? DbFuncs.GetTranslation(s.ActivityDetail.Description, null, s.ActivityDetail.DescriptionTid, currentCulture) : null))
                .ForMember(d => d.ActivityKey, opt => opt.MapFrom(s => s.ActivityDetail != null ? s.ActivityDetail.WipCode : null))
                .ForMember(d => d.CaseReference, opt => opt.MapFrom(s => s.Case == null ? null : s.Case.Irn))
                .ForMember(d => d.InstructorName,
                           opt => opt.MapFrom(s => s.Case != null
                                                  ? s.Case.CaseNames
                                                     .Where(cn => cn.NameType.NameTypeCode ==
                                                                  KnownNameTypes.Instructor)
                                                     .OrderBy(_ => _.Sequence)
                                                     .FirstOrDefault()
                                                     .Name
                                                  : null))
                .ForMember(d => d.DebtorName, opt => opt.MapFrom(s => s.Name))
                .ForMember(d => d.LocalValue, opt => opt.MapFrom(s => s.TimeValue))
                .ForMember(d => d.StaffId, opt => opt.MapFrom(s => s.EmployeeNo))
                .ForMember(d => d.LocalDiscount, opt => opt.MapFrom(s => s.DiscountValue))
                .ForMember(d => d.ExchangeRate, opt => opt.MapFrom(s => s.ExchRate))
                .ForMember(d => d.IsTimer, opt => opt.MapFrom(s => s.IsTimer > 0))
                .ForMember(d => d.NarrativeNo, opt => opt.MapFrom(s => s.Narrative != null ? s.Narrative.NarrativeId : (short?) null))
                .ForMember(d => d.NarrativeCode, opt => opt.MapFrom(s => s.Narrative != null ? s.Narrative.NarrativeCode : null))
                .ForMember(d => d.NarrativeTitle, opt => opt.MapFrom(s => s.Narrative != null ? DbFuncs.GetTranslation(s.Narrative.NarrativeTitle, null, s.Narrative.NarrativeTitleTid, currentCulture) : null))
                .ForMember(d => d.NarrativeText,
                           opt => opt.MapFrom(s => DbFuncs.GetTranslation(s.ShortNarrative,
                                                                          s.LongNarrative,
                                                                          s.LongNarrativeTId ?? s.ShortNarrativeTId,
                                                                          currentCulture) ??
                                                   (s.Narrative != null
                                                       ? DbFuncs.GetTranslation(s.Narrative.NarrativeText,
                                                                                null,
                                                                                s.Narrative.NarrativeTextTid,
                                                                                currentCulture)
                                                       : null)))
                .ForMember(d => d.TotalUnits, opt => opt.MapFrom(s => (decimal?) s.TotalUnits))
                .ForMember(d => d.IsCaseOnlyTime, opt => opt.MapFrom(s => caseOnlyTime))
                .ForMember(d => d.WipEntityNo, opt => opt.MapFrom(s => s.WipEntityId))
                .ForMember(d => d.TransNo, opt => opt.MapFrom(s => s.TransactionId))
                .ForMember(d => d.DebtorSplits,
                           opt =>
                           {
                               opt.PreCondition((diary, context) => isMultiDebtorEnabled);
                               opt.MapFrom(s => s.DebtorSplits);
                           })
                .ReverseMap()
                .ForMember(d => d.DebtorSplits, opt => opt.Ignore())
                .ForMember(d => d.TotalUnits, opt => opt.MapFrom(s => s.TotalUnits))
                .ForMember(d => d.ChargeOutRate, opt => opt.MapFrom(s => s.ChargeOutRate))
                .ForMember(d => d.ForeignValue, opt => opt.MapFrom(s => s.ForeignValue))
                .ForMember(d => d.ForeignDiscount, opt => opt.MapFrom(s => s.ForeignDiscount))
                .ForMember(d => d.ForeignCurrency, opt => opt.MapFrom(s => s.ForeignCurrency))
                .ForMember(d => d.MarginId, opt => opt.MapFrom(s => s.MarginNo))
                .ForMember(d => d.CostCalculation1, opt => opt.MapFrom(s => s.CostCalculation1))
                .ForMember(d => d.CostCalculation2, opt => opt.MapFrom(s => s.CostCalculation2))
                .ForMember(d => d.UnitsPerHour, opt => opt.MapFrom(s => s.UnitsPerHour))
                .ForMember(d=> d.WipEntityId, opt=> opt.Ignore())
                .ForMember(d=> d.TransactionId, opt=> opt.Ignore())
                .ForAllOtherMembers(opt => opt.Ignore());

            CreateMap<DebtorSplitDiary, DebtorSplit>().ReverseMap();
        }
    }
}
