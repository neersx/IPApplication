using InprotechKaizen.Model.Cases;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDCHECKLISTS")]
    public class ValidChecklist
    {
        public ValidChecklist()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidChecklist(
            Country country,
            PropertyType propertyType, CaseType caseType, short checklistType, string checklistDescription)
        {
            if(country == null) throw new ArgumentNullException("country");
            if(caseType == null) throw new ArgumentNullException("caseType");
            if(propertyType == null) throw new ArgumentNullException("propertyType");

            CountryId = country.Id;
            PropertyTypeId = propertyType.Code;
            CaseTypeId = caseType.Code;
            ChecklistType = checklistType;
            ChecklistDescription = checklistDescription;
            Country = country;
            PropertyType = propertyType;
            CaseType = caseType;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidChecklist(
            Country country,
            PropertyType propertyType, CaseType caseType, CheckList checkList)
        {
            if (country == null) throw new ArgumentNullException("country");
            if (caseType == null) throw new ArgumentNullException("caseType");
            if (checkList == null) throw new ArgumentNullException("checkList");
            if (propertyType == null) throw new ArgumentNullException("propertyType");

            CountryId = country.Id;
            PropertyTypeId = propertyType.Code;
            CaseTypeId = caseType.Code;
            ChecklistType = checkList.Id;
            ChecklistDescription = checkList.Description;
            Country = country;
            PropertyType = propertyType;
            CaseType = caseType;
            CheckList = checkList;
        }

        [Key]
        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [Key]
        [Column("CHECKLISTTYPE")]
        public short ChecklistType { get; set; }

        [Key]
        [MaxLength(50)]
        [Column("CHECKLISTDESC")]
        public string ChecklistDescription { get; set; }

        [Column("CHECKLISTDESC_TID")]
        public int? ChecklistDescriptionTId { get; set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; protected set; }

        [ForeignKey("CountryId")]
        public virtual Country Country { get; protected set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; protected set; }

        [ForeignKey("ChecklistType")]
        public virtual CheckList CheckList { get; protected set; }
    }
}
