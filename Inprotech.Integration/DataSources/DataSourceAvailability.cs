using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.DataSources
{
    [Table("DataSourceAvailability")]
    public class DataSourceAvailability
    {
        [Key]
        [Column("Id")]
        public long Id { get; set; }

        [Required]
        public DataSourceType Source { get; set; }

        [Required]
        public string UnavailableDays { get; set; }

        [Required]
        [Column("StartTime")]
        public string StartTimeValue { get; set; }

        [Required]
        [Column("EndTime")]
        public string EndTimeValue { get; set; }

        [Required]
        public string TimeZone { get; set; }

        [NotMapped]
        public TimeSpan StartTime
        {
            get { return TimeSpan.Parse(StartTimeValue); }
            set { StartTimeValue = value.ToString(); }
        }

        [NotMapped]
        public TimeSpan EndTime
        {
            get { return TimeSpan.Parse(EndTimeValue); }
            set { EndTimeValue = value.ToString(); }
        }
    }

}