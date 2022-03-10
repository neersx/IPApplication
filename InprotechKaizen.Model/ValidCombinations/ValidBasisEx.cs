using InprotechKaizen.Model.Cases;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDBASISEX")]
    public class ValidBasisEx
    {
        public ValidBasisEx()
        {
            
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidBasisEx(CaseType caseType,
            CaseCategory caseCategory, ValidBasis validBasis)
        {
            if (caseType == null) throw new ArgumentNullException("caseType");
            if (caseCategory == null) throw new ArgumentNullException("caseCategory");
            if (validBasis == null) throw new ArgumentNullException("validBasis");

            CountryId = validBasis.Country.Id;
            PropertyTypeId = validBasis.PropertyType.Code;
            BasisId = validBasis.Basis.Code;
            CaseTypeId = caseType.Code;
            CaseCategoryId = caseCategory.CaseCategoryId;
            CaseType = caseType;
            CaseCategory = caseCategory;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidBasisEx(CaseType caseType,
            CaseCategory caseCategory)
        {
            if (caseType == null) throw new ArgumentNullException("caseType");
            if (caseCategory == null) throw new ArgumentNullException("caseCategory");

            CaseTypeId = caseType.Code;
            CaseCategoryId = caseCategory.CaseCategoryId;
            CaseType = caseType;
            CaseCategory = caseCategory;
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

        [Key]
        [MaxLength(2)]
        [Column("BASIS")]
        public string BasisId { get; set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; protected set; }

        public virtual ValidBasis ValidBasis { get; protected set; }

        public virtual CaseCategory CaseCategory { get; protected set; }

    }
}
