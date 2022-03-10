using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("BATCHTYPERULES")]
    public class BatchTypeRule
    {
        [Key]
        [Column("BATCHTYPERULENO")]
        public int BatchTypeRuleNo { get; set; }

        [Column("BATCHTYPE")]
        public int BatchType { get; set; }

        [Column("FROMNAMENO")]
        public int? FromNameNo { get; set; }

        [Column("HEADERINSTRUCTOR")]
        public int? HeaderInstructor { get; set; }

        [Column("HEADERSTAFFNAME")]
        public int? HeaderStaffName { get; set; }

        [Column("IMPORTEDINSTRUCTOR")]
        public int? ImportedInstructor { get; set; }

        [Column("IMPORTEDSTAFFNAME")]
        public int? ImportedStaffName { get; set; }

        [Column("REJECTEDINSTRUCTOR")]
        public int? RejectedInstructor { get; set; }

        [Column("REJECTEDSTAFFNAME")]
        public int? RejectedStaffName { get; set; }

        [StringLength(3)]
        [Column("INSTRUCTORNAMETYPE")]
        public string InstructorNameType { get; set; }
    }
}