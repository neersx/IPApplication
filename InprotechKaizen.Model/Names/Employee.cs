using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("EMPLOYEE")]
    public class Employee
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("EMPLOYEENO")]
        public int Id { get; set; }

        [MaxLength(10)]
        [Column("ABBREVIATEDNAME")]
        public string AbbreviatedName { get; set; }

        [Column("STARTDATE")]
        public DateTime? StartDate { get; set; }

        [MaxLength(6)]
        [Column("PROFITCENTRECODE")]
        public string ProfitCentre { get; set; }

        [Column("STAFFCLASS")]
        public int? StaffClassification { get; set; }

        [Column("CAPACITYTOSIGN")]
        public int? CapacityToSign { get; set; }

        [Column("DEFAULTENTITYNO")]
        public int? DefaultEntityId { get; set; }

        [MaxLength(50)]
        [Column("SIGNOFFNAME")]
        public string SignOffName { get; set; }
    }
}
