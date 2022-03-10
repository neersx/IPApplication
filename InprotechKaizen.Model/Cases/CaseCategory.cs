using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASECATEGORY")]
    public class CaseCategory
    {
        [Obsolete("For persistence only.")]
        public CaseCategory()
        {
        }

        public CaseCategory(string caseTypeCode, string caseCategoryId, string name)
        {
            if(string.IsNullOrEmpty(caseTypeCode)) throw new ArgumentException("A valid case category is required");
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Case Category is required.");
            if(string.IsNullOrWhiteSpace(caseCategoryId)) throw new ArgumentException("A valid id is required.");

            Name = name;
            CaseCategoryId = caseCategoryId;
            CaseTypeId = caseTypeCode;
        }

        [Column("CASECATEGORYID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("CASETYPE", Order = 1)]
        public string CaseTypeId { get; set; }

        [Key]
        [MaxLength(2)]
        [Column("CASECATEGORY", Order = 2)]
        public string CaseCategoryId { get; set; }

        [MaxLength(50)]
        [Column("CASECATEGORYDESC")]
        public string Name { get; set; }

        [Column("CASECATEGORYDESC_TID")]
        public int? NameTId { get; set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; set; }

        public override string ToString()
        {
            return Name;
        }
    }
}