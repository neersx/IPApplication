using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;

namespace InprotechKaizen.Model.Rules
{
    [Table("ADJUSTMENT")]
    public class DateAdjustment
    {
        [Obsolete("For persistence only.")]
        public DateAdjustment()
        {
        }

        [Key]
        [Column("ADJUSTMENT")]
        [MaxLength(4)]
        public string Id { get; internal set; }

        [MaxLength(50)]
        [Column("ADJUSTMENTDESC")]
        public string Description { get; set; }

        [Column("ADJUSTMENTDESC_TID")]
        public int? DescriptionTId { get; set; }

        [Column("ADJUSTDAY")]
        public decimal? AdjustDay { get; set; }

        [Column("ADJUSTMONTH")]
        public decimal? AdjustMonth { get; set; }

        [Column("ADJUSTYEAR")]
        public decimal? AdjustYear { get; set; }

        [Column("ADJUSTAMOUNT")]
        public short? AdjustAmount { get; set; }

        [MaxLength(1)]
        [Column("PERIODTYPE")]
        public string PeriodType { get; set; }
    }

    public static class DateAdjustmentExt
    {
        public static IOrderedEnumerable<DateAdjustment> SortForPickList(this DateAdjustment[] adjustments)
        {
            return adjustments.OrderBy(GetPicklistSortOrder)
                              .ThenByDescending(AdjustPeriodDays)
                              .ThenBy(_ => _.PeriodType)
                              .ThenByDescending(_ => _.AdjustYear)
                              .ThenBy(_ => _.AdjustMonth)
                              .ThenBy(_ => _.AdjustDay)
                              .ThenBy(_ => _.Description);
        }

        static int GetPicklistSortOrder(DateAdjustment d)
        {
            if (d.AdjustDay == null && d.AdjustMonth == null && d.AdjustYear == null && d.AdjustAmount == null)
                return 0;

            if (d.AdjustDay == null && d.AdjustMonth == null && d.AdjustYear == null && d.AdjustAmount != null)
                return 1;

            if (d.AdjustDay != null && d.AdjustMonth == null && d.AdjustYear == null)
                return 2;

            if (d.AdjustDay != null && d.AdjustMonth != null && d.AdjustYear == null)
                return 3;

            if (d.AdjustDay == null && d.AdjustMonth != null && d.AdjustYear == null)
                return 4;

            if (d.AdjustDay == null && d.AdjustMonth != null && d.AdjustYear != null)
                return 5;

            if (d.AdjustDay != null && d.AdjustMonth != null && d.AdjustYear != null)
                return 6;

            return 7;
        }

        static int? AdjustPeriodDays(DateAdjustment d)
        {
            if (d.AdjustAmount == null) return null;

            var days = 1;
            switch (d.PeriodType)
            {
                case "W":
                    days = 7;
                    break;
                case "M":
                    days = 30;
                    break;
                case "Y":
                    days = 365;
                    break;
            }

            return d.AdjustAmount.Value * days;
        }
    }
}