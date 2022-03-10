using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Time
{
    public interface IDiaryDatesReader
    {
        Task<IEnumerable<PostableDate>> GetDiaryDatesFor(int employeeId, DateTime tillDate);
        Task<IEnumerable<DateTime>> GetDiaryDatesFor(int employeeId, int[] entryNos);
        Task<IEnumerable<PostableDate>> GetDiaryDatesFor(DateTime? from, DateTime? to);
    }

    public class DiaryDatesReader : IDiaryDatesReader
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IDisplayFormattedName _displayFormattedName;

        public DiaryDatesReader(IDbContext dbContext, ISiteControlReader siteControlReader, IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _displayFormattedName = displayFormattedName;
        }

        public async Task<IEnumerable<PostableDate>> GetDiaryDatesFor(int employeeId, DateTime tillDate)
        {
            var caseOnly = _siteControlReader.Read<bool>(SiteControls.CASEONLY_TIME);
            var rateMandatory = _siteControlReader.Read<bool>(SiteControls.RateMandatoryOnTimeItems);
            var diary = await _dbContext.Set<Diary>()
                                        .Where(_ => _.StartTime != null || _.FinishTime != null)
                                        .Where(_ => _.EmployeeNo == employeeId && _.StartTime < tillDate)
                                        .ExcludeEntriesWithoutCase(caseOnly)
                                        .ExcludeEntriesWithoutActivity()
                                        .ExcludePosted()
                                        .ExcludeContinuedParentEntries()
                                        .ExcludeRunningTimerEntries()
                                        .ExcludeEntriesWithoutRate(rateMandatory)
                                        .ExcludeEntriesWithNoDuration()
                                        .ToArrayAsync();

            return from d in diary
                   group d by d.StartTime?.Date ?? d.FinishTime.GetValueOrDefault().Date
                   into g
                   select new PostableDate(g.Key,
                                           new TimeSpan(g.Sum(_ => _.TotalTime.GetValueOrDefault().TimeOfDay.Ticks + _.TimeCarriedForward.GetValueOrDefault().TimeOfDay.Ticks)).TotalSeconds,
                                           new TimeSpan(g.Where(i => i.TimeValue != null && i.TimeValue != decimal.Zero).Sum(_ => _.TotalTime.GetValueOrDefault().TimeOfDay.Ticks + _.TimeCarriedForward.GetValueOrDefault().TimeOfDay.Ticks)).TotalSeconds);
        }

        public async Task<IEnumerable<DateTime>> GetDiaryDatesFor(int employeeId, int[] entryNos)
        {
            var caseOnly = _siteControlReader.Read<bool>(SiteControls.CASEONLY_TIME);
            var rateMandatory = _siteControlReader.Read<bool>(SiteControls.RateMandatoryOnTimeItems);
            var diary = await _dbContext.Set<Diary>()
                                        .Where(_ => _.StartTime != null || _.FinishTime != null)
                                        .Where(_ => _.EmployeeNo == employeeId && entryNos.Contains(_.EntryNo))
                                          .ExcludeEntriesWithoutCase(caseOnly)
                                          .ExcludeEntriesWithoutActivity()
                                          .ExcludePosted()
                                          .ExcludeContinuedParentEntries()
                                          .ExcludeRunningTimerEntries()
                                          .ExcludeEntriesWithoutRate(rateMandatory)
                                          .ExcludeEntriesWithNoDuration()
                                          .ToArrayAsync();

            return from d in diary
                   group d by d.StartTime?.Date ?? d.FinishTime.GetValueOrDefault().Date
                   into g
                   select g.Key;
        }

        public async Task<IEnumerable<PostableDate>> GetDiaryDatesFor(DateTime? from, DateTime? to)
        {
            var caseOnly = _siteControlReader.Read<bool>(SiteControls.CASEONLY_TIME);
            var rateMandatory = _siteControlReader.Read<bool>(SiteControls.RateMandatoryOnTimeItems);
            var diary = await _dbContext.Set<Diary>()
                                        .Where(_ => _.StartTime != null || _.FinishTime != null)
                                        .Where(_ => _.StartTime > from && _.StartTime < to)
                                        .ExcludeEntriesWithoutCase(caseOnly)
                                        .ExcludeEntriesWithoutActivity()
                                        .ExcludePosted()
                                        .ExcludeContinuedParentEntries()
                                        .ExcludeRunningTimerEntries()
                                        .ExcludeEntriesWithoutRate(rateMandatory)
                                        .ExcludeEntriesWithNoDuration()
                                        .ToArrayAsync();
            var nameIds = diary.Select(v => v.EmployeeNo).Distinct().ToArray();
            var formattedNames = await _displayFormattedName.For(nameIds);

            var result = from d in diary
                   group d by new { Date = d.StartTime?.Date ?? d.FinishTime.GetValueOrDefault().Date, d.EmployeeNo }
                   into g
                   let staffName = formattedNames[g.Key.EmployeeNo].Name
                   where staffName != null
                   select new PostableDate(g.Key.Date,
                                           new TimeSpan(g.Sum(_ => _.TotalTime.GetValueOrDefault().TimeOfDay.Ticks + _.TimeCarriedForward.GetValueOrDefault().TimeOfDay.Ticks)).TotalSeconds,
                                           new TimeSpan(g.Where(i => i.TimeValue != null && i.TimeValue != decimal.Zero).Sum(_ => _.TotalTime.GetValueOrDefault().TimeOfDay.Ticks + _.TimeCarriedForward.GetValueOrDefault().TimeOfDay.Ticks)).TotalSeconds,
                                           staffName,
                                           g.Key.EmployeeNo);

            return result;
        }
    }
}