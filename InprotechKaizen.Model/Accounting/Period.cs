using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("PERIOD")]
    public class Period
    {
        [Obsolete("For Persistence Only...")]
        public Period()
        {
        }

        public Period(string label, DateTime startDate, DateTime endDate)
        {
            if(label == null) throw new ArgumentNullException("label");
            if(startDate > endDate) throw new ArgumentException("start date must be equal or greater than end date");

            Label = label;
            StartDate = startDate;
            EndDate = endDate;
        }

        [Key]
        [Column("PERIODID")]
        public int Id { get; set; }

        [MaxLength(20)]
        [Column("LABEL")]
        public string Label { get; set; }

        [Column("STARTDATE")]
        public DateTime StartDate { get; set; }

        [Column("ENDDATE")]
        public DateTime EndDate { get; set; }

        [Column("CLOSEDFOR", TypeName = "numeric")]
        public SystemIdentifier? ClosedForModules { get; set; }

        [Column("POSTINGCOMMENCED")]
        public DateTime? PostingCommenced { get; set; }
    }
}