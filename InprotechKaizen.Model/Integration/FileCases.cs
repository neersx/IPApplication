using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Integration
{
    [Table("FILECASE")]
    public class FileCase
    {
        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Column("CASEID")]
        [ForeignKey("Case")]
        public int CaseId { get; set; }

        [Column("PARENTCASEID")]
        public int? ParentCaseId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("IPTYPE")]
        public string IpType { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [MaxLength(50)]
        [Column("STATUS")]
        public string Status { get; set; }

        [Column("INSTRUCTIONID")]
        public Guid? InstructionGuid { get; set; }

        public virtual Case Case { get; protected set; }
        
    }
}