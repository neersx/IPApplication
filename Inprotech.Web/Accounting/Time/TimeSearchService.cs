using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Time.Search;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Persistence;
using ServiceStack;

namespace Inprotech.Web.Accounting.Time
{
    public interface ITimeSearchService
    {
        IQueryable<TimeEntry> Search(TimeSearchParams searchParams, IEnumerable<CommonQueryParameters.FilterValue> filters);
    }

    public class TimeSearchService : ITimeSearchService
    {
        const string Start = "ENTRYDATE";
        const string CaseReference = "CASEREFERENCE";
        const string Name = "NAME";
        const string Activity = "ACTIVITY";

        readonly ITimesheetList _timeSheetList;

        public TimeSearchService(ITimesheetList timeSheetList)
        {
            _timeSheetList = timeSheetList;
        }

        public IQueryable<TimeEntry> Search(TimeSearchParams searchParams, IEnumerable<CommonQueryParameters.FilterValue> filters)
        {
            var query = _timeSheetList.SearchFor(searchParams);
            foreach (var filter in filters)
            {
                switch (filter.Field.ToUpper())
                {
                    case Start:
                        var (containsEmptyDates, listDates) = SplitToList<DateTime>(filter.Value);
                        var dates = listDates.Select(_ => _.Date);
                        query = query.Where(_ => containsEmptyDates && _.StartTime == null || _.StartTime != null && dates.Contains(DbFuncs.TruncateTime(_.StartTime).Value));
                        break;

                    case CaseReference:
                        var (containsEmptyCaseIds, listCaseIds) = SplitToList<int>(filter.Value);
                        query = query.Where(_ => containsEmptyCaseIds && _.CaseKey == null ||
                                                 _.CaseKey != null && listCaseIds.Contains((int) _.CaseKey));
                        break;

                    case Name:
                        var (containsEmptyNames, listNameIds) = SplitToList<int>(filter.Value);
                        query = query.Where(_ => containsEmptyNames && _.InstructorName == null && _.DebtorName == null ||
                                                 _.InstructorName != null && listNameIds.Contains(_.InstructorName.Id) ||
                                                 _.InstructorName == null && _.DebtorName != null && listNameIds.Contains(_.DebtorName.Id));
                        break;

                    case Activity:
                        var (containsEmptyActivity, listActivityIds) = SplitToList<string>(filter.Value);
                        query = query.Where(_ => containsEmptyActivity && _.ActivityKey == null ||
                                                 _.ActivityKey != null && listActivityIds.Contains(_.ActivityKey));
                        break;
                }
            }

            return query;

            (bool containsEmpty, List<T> list) SplitToList<T>(string filterValue)
            {
                var stringIds = filterValue.Split(',');
                return (stringIds.Any(string.IsNullOrWhiteSpace), stringIds.Where(_ => !string.IsNullOrWhiteSpace(_)).ToList().ConvertTo<List<T>>());
            }
        }
    }
}