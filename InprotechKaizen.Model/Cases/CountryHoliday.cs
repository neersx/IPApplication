using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("HOLIDAYS")]
    public class CountryHoliday
    {
        [Obsolete("For persistence only...")]
        public CountryHoliday()
        {
        }

        public CountryHoliday(string countryCode, DateTime holidayDate)
        {
            if (countryCode == null) throw new ArgumentNullException("countryCode");

            CountryId = countryCode;
            HolidayDate = holidayDate;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Column("COUNTRYCODE", Order = 0)]
        [MaxLength(3)]
        public string CountryId { get; set; }

        [Column("HOLIDAYDATE", Order = 1)]
        public DateTime HolidayDate { get; set; }

        [MaxLength(50)]
        [Column("HOLIDAYNAME")]
        public string HolidayName { get; set; }
    }
}