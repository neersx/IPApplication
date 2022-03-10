using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASETYPE")]
    public class CaseType
    {
        [Obsolete("For persistence only.")]
        public CaseType()
        {
        }

        public CaseType(string code, string name)
        {
            if (string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Case Type is required.");
            if (string.IsNullOrWhiteSpace(code)) throw new ArgumentException("A valid code is required.");

            Name = name;
            Code = code;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [Column("CASETYPE")]
        [MaxLength(1)]
        public string Code { get; internal set; }

        [MaxLength(50)]
        [Column("CASETYPEDESC")]
        public string Name { get; set; }

        [Column("CASETYPEDESC_TID")]
        public int? NameTId { get; set; }

        [Column("PROGRAM")]
        public int? Program { get; set; }

        [MaxLength(1)]
        [Column("ACTUALCASETYPE")]
        public string ActualCaseTypeId { get; set; }

        [MaxLength(2)]
        [Column("KOTTEXTTYPE")]
        public string KotTextType { get; set; }

        [Column("CRMONLY")]
        public bool? CrmOnly { get; set; }

        [ForeignKey("ActualCaseTypeId")]
        public virtual CaseType ActualCaseType { get; set; }

        public virtual TextType TextType { get; set; }

        public override string ToString()
        {
            return Name;
        }
    }
}