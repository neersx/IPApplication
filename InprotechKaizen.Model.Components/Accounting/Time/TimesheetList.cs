using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using AutoMapper.QueryableExtensions;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class TimesheetList : ITimesheetList
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCulture;
        readonly ISiteControlReader _siteControls;
        readonly IDisplayFormattedName _displayFormattedName;
        readonly Func<DateTime> _now;
        readonly IMapper _mapper;
        bool _caseOnlyTime;

        public TimesheetList(IDbContext dbContext, IPreferredCultureResolver preferredCulture, ISiteControlReader siteControls, IDisplayFormattedName displayFormattedName, Func<DateTime> now, IMapper mapper)
        {
            _dbContext = dbContext;
            _preferredCulture = preferredCulture;
            _siteControls = siteControls;
            _displayFormattedName = displayFormattedName;
            _now = now;
            _mapper = mapper;
        }

        IQueryable<Diary> DiarySet => _dbContext.Set<Diary>().Include(_ => _.DebtorSplits);

        public IQueryable<Diary> GetRunningTimersFor(int staffId, DateTime? selectedDate = null, int? entryNo = null)
        {
            if (entryNo.HasValue)
            {
                return DiarySet.Where(_ => _.EntryNo == entryNo && _.EmployeeNo == staffId && _.IsTimer == 1);
            }

            if (selectedDate.HasValue)
            {
                return DiaryFor(staffId, selectedDate.Value.Date).Where(_ => _.IsTimer > 0);
            }

            var today = _now().Date;
            return DiarySet.Where(d => d.EmployeeNo == staffId && d.IsTimer > 0 && DbFuncs.TruncateTime(d.StartTime) < today);
        }

        public IQueryable<Diary> DiaryFor(int staffId, DateTime selectedDate)
        {
            return from d in DiarySet
                   where d.EmployeeNo == staffId && DbFuncs.TruncateTime(d.StartTime) == selectedDate.Date && (DbFuncs.TruncateTime(d.FinishTime) == selectedDate.Date || d.FinishTime == null && d.IsTimer > 0)
                   select d;
        }

        public IQueryable<Diary> DiaryFor(int staffId, params int[] entryNos)
        {
            return from d in DiarySet
                   where d.EmployeeNo == staffId && entryNos.Contains(d.EntryNo)
                   select d;
        }

        public async Task<IEnumerable<TimeGap>> TimeGapFor(int staffId, DateTime selectedDate)
        {
            var diaries = await DiaryFor(staffId, selectedDate).Where(_ => _.StartTime.HasValue && _.FinishTime.HasValue && _.StartTime != _.FinishTime)
                                                               .OrderBy(_ => _.StartTime)
                                                               .Select(_ => new {StartTime = _.StartTime.Value, FinishTime = _.FinishTime.Value})
                                                               .ToListAsync();

            var localSelectedDate = DateTime.SpecifyKind(selectedDate, DateTimeKind.Unspecified);
            if (!diaries.Any())
            {
                return new[]
                {
                    new TimeGap {Id = 1, StaffId = staffId, EntryDate = selectedDate.Date, StartTime = localSelectedDate, FinishTime = localSelectedDate.Date.Add(new TimeSpan(23, 59, 59))}
                };
            }

            var gaps = new List<TimeGap> {new TimeGap {Id = 1, StaffId = staffId, EntryDate = selectedDate.Date, StartTime = localSelectedDate, FinishTime = diaries.First().StartTime}};
            gaps.AddRange(diaries.Zip(diaries.Skip(1), (d1, d2) => new TimeGap {Id = gaps.Count + 1, StaffId = staffId, EntryDate = selectedDate.Date, StartTime = d1.FinishTime, FinishTime = d2.StartTime}));
            gaps.Add(new TimeGap {Id = gaps.Count + 1, StaffId = staffId, EntryDate = selectedDate.Date, StartTime = diaries.Last().FinishTime, FinishTime = localSelectedDate.Add(new TimeSpan(23, 59, 59))});

            return gaps.Where(_ => _.DurationInSeconds > 60);
        }

        public async Task<IEnumerable<TimeEntry>> Get(int staffId, IQueryable<Diary> query = null, params int[] entryNos)
        {
            var culture = _preferredCulture.Resolve();
            _caseOnlyTime = _siteControls.Read<bool>(SiteControls.CASEONLY_TIME);
            var isMultiDebtorEnabled = _siteControls.Read<bool>(SiteControls.WIPSplitMultiDebtor);

            var queryWithEntryNo = entryNos.Any() ? DiarySet.Where(_ => _.EmployeeNo == staffId && entryNos.Contains(_.EntryNo)) : null;
            var newQuery = query != null ? queryWithEntryNo != null ? query.Concat(queryWithEntryNo) : query : queryWithEntryNo;

            var diaryEntries = await newQuery
                                     .ProjectTo<TimeEntry>(_mapper.ConfigurationProvider, new {currentCulture = culture, isMultiDebtorEnabled})
                                     .ToListAsync();
            if (!diaryEntries.Any())
                return Enumerable.Empty<TimeEntry>();

            diaryEntries.ForEach(d => d.IsCaseOnlyTime = _caseOnlyTime);

            var ids = diaryEntries.Select(_ => _.InstructorName?.Id).Concat(diaryEntries.Select(_ => _.DebtorName?.Id)).ToArray();
            
            if (!ids.Any(_ => _.HasValue))
                return diaryEntries;

            var formattedNames = await _displayFormattedName.For(ids.Where(_ => _.HasValue).Select(_ => _.Value).Distinct().ToArray());
            if (!formattedNames.Any())
                return diaryEntries;

            diaryEntries.ForEach(diaryEntry =>
            {
                if (diaryEntry.DebtorName != null && formattedNames.ContainsKey(diaryEntry.DebtorName.Id))
                    diaryEntry.Debtor = formattedNames[diaryEntry.DebtorName.Id]?.Name;
                else if (diaryEntry.InstructorName != null && formattedNames.ContainsKey(diaryEntry.InstructorName.Id))
                    diaryEntry.Instructor = formattedNames[diaryEntry.InstructorName.Id].Name;
            });

            return diaryEntries;
        }

        public async Task<IEnumerable<TimeEntry>> For(int staffId, DateTime selectedDate)
        {
            var culture = _preferredCulture.Resolve();
            _caseOnlyTime = _siteControls.Read<bool>(SiteControls.CASEONLY_TIME);
            var isMultiDebtorEnabled = _siteControls.Read<bool>(SiteControls.WIPSplitMultiDebtor);

            var list = await DiaryFor(staffId, selectedDate).ProjectTo<TimeEntry>(_mapper.ConfigurationProvider, new {currentCulture = culture, isMultiDebtorEnabled}).ToListAsync();
            list.ForEach(_ => _.IsCaseOnlyTime = _caseOnlyTime);
            list.ForEach(_ => _.ChargeOutRate = isMultiDebtorEnabled && (_.DebtorSplits.DistinctBy(s => s.ChargeOutRate).Count() > 1 || _.DebtorSplits.DistinctBy(s => s.ForeignCurrency).Count() > 1) ? null : _.ChargeOutRate);
            await FormatNamesForDisplay(list);

            return list.OrderBy(_ => _.IsHoursOnly).ThenByDescending(_ => _.IsHoursOnly ? _.CreatedOn : _.StartTime);
        }

        public IQueryable<TimeEntry> SearchFor(TimeSearchParams searchParams)
        {
            var query = (from d in DiarySet
                         where d.EmployeeNo == searchParams.StaffId && d.IsTimer == 0 && d.TotalTime.HasValue
                         select d)
                        .ApplyDateFilters(searchParams.FromDate, searchParams.ToDate)
                        .ApplyEntityFilter(searchParams.Entity)
                        .ApplyCaseFilter(searchParams.CaseIds)
                        .ApplyPostedUnpostedFilter(searchParams.IsPostedOnly, searchParams.IsUnpostedOnly)
                        .ApplyActivityFilter(searchParams.ActivityId)
                        .ApplyNameFilter(searchParams.NameId, searchParams.AsDebtor, searchParams.AsInstructor)
                        .ApplyNarrativeFilter(searchParams.NarrativeSearch);

            return Project(query);
        }

        public IQueryable<TimeEntry> SearchFor(int staffId, IEnumerable<int> entryNos)
        {
            var query = from d in DiarySet
                        where d.EmployeeNo == staffId && d.IsTimer == 0 && d.TotalTime.HasValue && entryNos.Contains(d.EntryNo)
                        select d;

            return Project(query);
        }

        public IQueryable<TimeEntry> SearchForAll()
        {
            var query = from d in DiarySet
                        where d.IsTimer == 0 && d.TotalTime.HasValue
                        select d;

            return Project(query);
        }

        IQueryable<TimeEntry> Project(IQueryable<Diary> query)
        {
            var culture = _preferredCulture.Resolve();
            _caseOnlyTime = _siteControls.Read<bool>(SiteControls.CASEONLY_TIME);
            var isMultiDebtorEnabled = _siteControls.Read<bool>(SiteControls.WIPSplitMultiDebtor);
            var list = query.ToList();
            _mapper.Map<TimeEntry>(list.FirstOrDefault());
            return query.ProjectTo<TimeEntry>(_mapper.ConfigurationProvider, new {currentCulture = culture, caseOnlyTime = _caseOnlyTime, isMultiDebtorEnabled});
        }

        public async Task FormatNamesForDisplay(List<TimeEntry> list)
        {
            var instructorIds = list.Where(_ => _.InstructorName != null).Select(_ => _.InstructorName.Id);
            var debtorIds = list.Where(_ => _.DebtorName != null).Select(_ => _.DebtorName.Id);
            var splitDebtorIds = new List<int>();
            list.ForEach(_ =>
            {
                splitDebtorIds.AddRange(_.DebtorSplits.Select(d => d.DebtorNameNo));
            });
            var formattedNames = await _displayFormattedName.For(instructorIds.Concat(debtorIds).Concat(splitDebtorIds).Distinct().ToArray());

            if (formattedNames.Any())
            {
                foreach (var timeEntry in list)
                {
                    if (timeEntry.DebtorName != null && formattedNames.ContainsKey(timeEntry.DebtorName.Id))
                        timeEntry.Debtor = formattedNames[timeEntry.DebtorName.Id]?.Name;
                    else if (timeEntry.InstructorName != null && formattedNames.ContainsKey(timeEntry.InstructorName.Id))
                        timeEntry.Instructor = formattedNames[timeEntry.InstructorName.Id].Name;

                    timeEntry.DebtorSplits.ForEach(_ =>
                    {
                        _.DebtorName = formattedNames[_.DebtorNameNo]?.Name;
                    });
                }
            }
        }

        public async Task<IEnumerable<Diary>> GetWholeChainFor(int staffId, int entryNo, DateTime? dateTime)
        {
            if (!dateTime.HasValue)
            {
                var entry = await DiarySet.SingleOrDefaultAsync(_ => _.EntryNo == entryNo);
                dateTime = entry?.StartTime?.Date;
            }

            if (!dateTime.HasValue) return Enumerable.Empty<Diary>();

            var allEntries = DiaryFor(staffId, dateTime.Value);
            return allEntries
                   .AsEnumerable()
                   .GetWholeChainFor(entryNo);
        }
    }

    public interface ITimesheetList
    {
        Task<IEnumerable<TimeEntry>> For(int staffId, DateTime selectedDate);

        Task<IEnumerable<TimeEntry>> Get(int staffId, IQueryable<Diary> query = null, params int[] entryNos);

        IQueryable<Diary> DiaryFor(int staffId, DateTime selectedDate);

        IQueryable<Diary> DiaryFor(int staffId, params int[] entryNos);

        Task<IEnumerable<TimeGap>> TimeGapFor(int staffId, DateTime selectedDate);

        IQueryable<Diary> GetRunningTimersFor(int staffId, DateTime? selectedDate = null, int? entryNo = null);

        IQueryable<TimeEntry> SearchFor(TimeSearchParams searchParams);

        IQueryable<TimeEntry> SearchFor(int staffId, IEnumerable<int> entryNos);

        IQueryable<TimeEntry> SearchForAll();

        Task FormatNamesForDisplay(List<TimeEntry> list);

        Task<IEnumerable<Diary>> GetWholeChainFor(int staffId, int entryNo, DateTime? dateTime);
    }

    public class TimeEntry
    {
        public string Instructor { get; set; }
        public string Debtor { get; set; }
        public int? CaseKey { get; set; }
        public int? NameKey => InstructorName?.Id ?? DebtorName?.Id;

        public DateTime? Start => StartTime?.Hour != 0 ||
                                  StartTime?.Minute != 0 ||
                                  StartTime?.Second != 0 ||
                                  FinishTime?.Hour != 0 ||
                                  FinishTime?.Minute != 0 ||
                                  FinishTime?.Second != 0
            ? StartTime
            : null;

        public DateTime? Finish => StartTime?.Hour != 0 ||
                                   StartTime?.Minute != 0 ||
                                   StartTime?.Second != 0 ||
                                   FinishTime?.Hour != 0 ||
                                   FinishTime?.Minute != 0 ||
                                   FinishTime?.Second != 0
            ? FinishTime
            : null;

        public int? ElapsedTimeInSeconds => TotalTime?.Hour * 3600 +
                                            TotalTime?.Minute * 60 +
                                            TotalTime?.Second;

        public string Name => Instructor ?? Debtor;

        public string CaseReference { get; set; }

        public string Activity { get; set; }
        public decimal? LocalValue { get; set; }
        public decimal? ForeignValue { get; set; }
        public string ForeignCurrency { get; set; }
        public string NarrativeText { get; set; }
        public string Notes { get; set; }
        public int StaffId { get; set; }
        public decimal? ChargeOutRate { get; set; }
        public decimal? LocalDiscount { get; set; }
        public decimal? ForeignDiscount { get; set; }
        public decimal? TotalUnits { get; set; }
        public bool IsPosted => WipEntityNo.HasValue && TransNo.HasValue;

        public bool IsIncomplete => !IsTimer && (IsIncompleteNoCase || TotalTime?.TimeOfDay == TimeSpan.Zero
                                                                    || string.IsNullOrWhiteSpace(ActivityKey)
                                                                    || CaseKey == null && NameKey == null);

        public int? EntryNo { get; set; }

        [JsonIgnore]
        public int? WipEntityNo { get; set; }

        [JsonIgnore]
        public int? TransNo { get; set; }

        [JsonIgnore]
        internal Case Case { get; set; }

        [JsonIgnore]
        public Name InstructorName { get; set; }

        [JsonIgnore]
        public Name DebtorName { get; set; }

        [JsonIgnore]
        public DateTime? StartTime { get; set; }

        [JsonIgnore]
        public DateTime? FinishTime { get; set; }

        [JsonIgnore]
        public DateTime? TotalTime { get; set; }

        [JsonIgnore]
        public bool IsCaseOnlyTime { get; set; }

        [JsonIgnore]
        public bool IsIncompleteNoCase => string.IsNullOrWhiteSpace(CaseReference) && IsCaseOnlyTime;

        public int? ParentEntryNo { get; set; }
        public short? NarrativeNo { get; set; }
        public string NarrativeTitle { get; set; }
        public string NarrativeCode { get; set; }
        public string ActivityKey { get; set; }

        [JsonIgnore]
        public DateTime? TimeCarriedForward { get; set; }

        public int? SecondsCarriedForward => TimeCarriedForward?.Hour * 3600 +
                                             TimeCarriedForward?.Minute * 60 +
                                             TimeCarriedForward?.Second;

        public decimal? ExchangeRate { get; set; }
        public bool IsTimer { get; set; }
        public int TotalDuration => SecondsCarriedForward.GetValueOrDefault() + ElapsedTimeInSeconds.GetValueOrDefault();
        public DateTime? EntryDate => StartTime.GetValueOrDefault().Date;
        public bool IsSplitDebtorWip { get; set; }
        public List<DebtorSplit> DebtorSplits { get; set; } = new List<DebtorSplit>();
        public string DebtorNameTypeKey { get; set; }
        public decimal? CostCalculation1 { get; set; }
        public decimal? CostCalculation2 { get; set; }
        public int? MarginNo { get; set; }
        public short? UnitsPerHour { get; set; }
        [JsonIgnore]
        public DateTime? CreatedOn { get; set; }

        public bool IsHoursOnly => !IsTimer && StartTime.GetValueOrDefault().TimeOfDay == TimeSpan.Zero && TotalTime?.TimeOfDay > TimeSpan.Zero;
    }

    public static class TimeEntryExt
    {
        public static TimeEntry MakeUiReady(this TimeEntry entry)
        {
            if (entry == null)
            {
                return null;
            }

            if (entry.StartTime.HasValue)
            {
                entry.StartTime = DateTime.SpecifyKind(entry.StartTime.GetValueOrDefault(), DateTimeKind.Unspecified);
            }

            if (entry.FinishTime.HasValue)
            {
                entry.FinishTime = DateTime.SpecifyKind(entry.FinishTime.GetValueOrDefault(), DateTimeKind.Unspecified);
            }

            return entry;
        }
    }
}
