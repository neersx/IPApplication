using System;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class TimeGap
    {
        public DateTime StartTime { get; set; }

        public DateTime FinishTime { get; set; }

        [JsonIgnore]
        public TimeSpan Duration => FinishTime - StartTime;

        public double DurationInSeconds => Duration.TotalSeconds;
        public int Id { get; set; }
        public DateTime EntryDate { get; set; }
        public int StaffId { get; set; }
        public int? EntryNo { get; set; }
    }
}