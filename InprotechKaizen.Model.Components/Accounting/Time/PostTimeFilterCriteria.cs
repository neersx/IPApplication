using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public static class PostTimeCriteriaHelper
    {
        public static PostTimeFilterCriteria ValidForPosting(this PostTimeFilterCriteria filterCriteria)
        {
            var f = filterCriteria ?? new PostTimeFilterCriteria();

            f.EntryTypeFilter.IsUnposted = true;
            f.EntryTypeFilter.IsContinued = false;
            f.EntryTypeFilter.IsIncomplete = true;
            f.EntryTypeFilter.IsPosted = false;
            f.EntryTypeFilter.IsTimer = false;

            return f;
        }
    }
    public class PostTimeFilterCriteria
    {
        public int? WipEntityId { get; set; }
        
        public class StaffFilterCriteria
        {
            public int? StaffNameId { get; set; }
            public bool IsCurrentUser { get; set; }
        }

        public class EntryTypeFilterCriteria
        {
            public bool IsUnposted { get; set; }
            public bool IsIncomplete { get; set; }
            public bool IsPosted { get; set; }
            public bool IsTimer { get; set; }
            public bool IsContinued { get; set; }
        }

        public class DateRangeCriteria
        {
            public DateTime ToDate { get; set; }
        }

        public IEnumerable<DateTime> EntryDates { get; set; }
        public IEnumerable<int> EntryNos { get; set; }
        public StaffFilterCriteria StaffFilter { get; set; } = new();
        public EntryTypeFilterCriteria EntryTypeFilter { get; set; } = new();
        public DateRangeCriteria DateRange { get; set; }
    }

    public static class PostTimeFilterBuilder
    {
        public static XElement Build(this PostTimeFilterCriteria filterCriteria)
        {
            if (filterCriteria == null) throw new ArgumentNullException(nameof(filterCriteria));

            return new XElement("ts_PostTime",
                                new XElement("ts_ListDiary", BuildListDiaryFilter(filterCriteria)),
                                BuildWipEntityElement(filterCriteria));
        }

        static XElement BuildListDiaryFilter(PostTimeFilterCriteria filterCriteria)
        {
            var listDiary = new XElement("FilterCriteria");

            if (filterCriteria.StaffFilter != null)
            {
                var staffKey = new XElement("StaffKey", filterCriteria.StaffFilter.StaffNameId);
                staffKey.SetAttributeValue("Operator", 0);
                staffKey.SetAttributeValue("IsCurrentUser", filterCriteria.StaffFilter.IsCurrentUser ? 1 : 0);
                listDiary.Add(staffKey);
            }

            var entryType = new XElement("EntryType");
            entryType.Add(new XElement("IsUnposted", filterCriteria.EntryTypeFilter.IsUnposted ? 1 : 0));
            entryType.Add(new XElement("IsContinued", filterCriteria.EntryTypeFilter.IsContinued ? 1 : 0));
            entryType.Add(new XElement("IsIncomplete", filterCriteria.EntryTypeFilter.IsIncomplete ? 1 : 0));
            entryType.Add(new XElement("IsPosted", filterCriteria.EntryTypeFilter.IsPosted ? 1 : 0));
            entryType.Add(new XElement("IsTimer", filterCriteria.EntryTypeFilter.IsTimer ? 1 : 0));
            listDiary.Add(entryType);

            if (filterCriteria.EntryNos != null && filterCriteria.EntryNos.Any())
            {
                listDiary.Add(new XElement("EntryNumbers", string.Join(",", filterCriteria.EntryNos)));
            }

            if (filterCriteria.EntryDates != null && filterCriteria.EntryDates.Any())
            {
                var entryDateGroup = new XElement("EntryDateGroup");
                entryDateGroup.SetAttributeValue("Operator", 0);
                foreach (var entryDate in filterCriteria.EntryDates)
                {
                    entryDateGroup.Add(new XElement("Date", $"{Convert.ToDateTime(entryDate):yyyy-MM-dd}"));
                }
                listDiary.Add(entryDateGroup);
            }

            if (filterCriteria.DateRange?.ToDate == null) 
                return listDiary;
            
            var dateRange = new XElement("DateRange");
            dateRange.SetAttributeValue("Operator", 7);
            dateRange.Add(new XElement("To", $"{filterCriteria.DateRange.ToDate.Date:yyyy-MM-dd}T00:00:00"));
            var entryDates = new XElement("EntryDate", dateRange);
            listDiary.Add(entryDates);

            return listDiary;
        }

        static XElement BuildWipEntityElement(PostTimeFilterCriteria filterCriteria)
        {
            return new XElement("WipEntityKey", filterCriteria.WipEntityId);
        }
    }
}