using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDCATEGORY")]
    public class ValidCategory
    {
        public ValidCategory()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidCategory(
            CaseCategory caseCategory,
            Country country,
            CaseType caseType,
            PropertyType propertyType, string validCategoryDesc)
        {
            if (caseCategory == null) throw new ArgumentNullException("caseCategory");
            if(country == null) throw new ArgumentNullException("country");
            if(caseType == null) throw new ArgumentNullException("caseType");
            if(propertyType == null) throw new ArgumentNullException("propertyType");
           
            CaseCategoryId = caseCategory.CaseCategoryId;
            CountryId = country.Id;
            PropertyTypeId = propertyType.Code;
            CaseTypeId = caseType.Code;
            CaseCategoryDesc = validCategoryDesc;
            Country = country;
            PropertyType = propertyType;
            CaseCategory = caseCategory;
            CaseType = caseType;
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
        [MaxLength(2)]
        [Column("CASECATEGORY")]
        public string CaseCategoryId { get; set; }
        
        [MaxLength(50)]
        [Column("CASECATEGORYDESC")]
        public string CaseCategoryDesc { get; set; }

        [Column("CASECATEGORYDESC_TID")]
        public int? CaseCategoryDescTid { get; set; }

        [Column("PROPERTYEVENTNO")]
        public int? PropertyEventNo { get; set; }

        [Column("MULTICLASSPROPERTYAPP")]
        public bool? MultiClassPropertyApp { get; set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; protected set; }

        public virtual Country Country { get; protected set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; protected set; }

        public virtual CaseCategory CaseCategory { get; set; }

        [ForeignKey("PropertyEventNo")]
        public virtual Event PropertyEvent { get; protected set; }
    }
}
