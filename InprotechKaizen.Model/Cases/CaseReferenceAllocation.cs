using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("IRALLOCATION")]
    public class CaseReferenceAllocation
    {
        [Key]
        [MaxLength(30)]
        [Column("IRN")]
        public string CaseReference { get; set; }

        [MaxLength(30)]
        [Column("USERID")]
        public string ApplicationUserId { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeId { get; set; }

        [Column("DATEALLOCATED")]
        public DateTime? DateAllocated { get; set; }

        [Column("IDENTITYID")]
        public int? IdentityId { get; set; }
    }
}