using System;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class PostableDate
    {
        public PostableDate(DateTime date, double totalTime, double totalChargableTime, string staffName = null!, int? staffNameId = null)
        {
            Date = date;
            TotalTimeInSeconds = totalTime;
            TotalChargableTimeInSeconds = totalChargableTime;
            StaffName = staffName;
            StaffNameId = staffNameId;
        }

        public DateTime Date { get; set; }
        public double? TotalTimeInSeconds { get; set; }
        public double? TotalChargableTimeInSeconds { get; set; }
        public string StaffName { get; set; }
        public int? StaffNameId { get; set; }
    }
}