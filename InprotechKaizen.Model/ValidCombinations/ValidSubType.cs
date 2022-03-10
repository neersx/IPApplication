using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDSUBTYPE")]
    public class ValidSubType
    {
        [Obsolete("For persistence only.")]
        public ValidSubType()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "subType")]
        public ValidSubType(string countryId, string propertyTypeId, string caseTypeId, string caseCategoryId,
            string subTypeId)
        {
            if (propertyTypeId == null) throw new ArgumentNullException("propertyTypeId");
            if (countryId == null) throw new ArgumentNullException("countryId");
            if (caseTypeId == null) throw new ArgumentNullException("caseTypeId");
            if (caseCategoryId == null) throw new ArgumentNullException("caseCategoryId");
            if (subTypeId == null) throw new ArgumentNullException("subTypeId");

            CountryId = countryId;
            PropertyTypeId = propertyTypeId;
            CaseTypeId = caseTypeId;
            CaseCategoryId = caseCategoryId;
            SubtypeId = subTypeId;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidSubType(
            ValidCategory validCategory,
            Country country,
            CaseType caseType,
            PropertyType propertyType, SubType subType)
        {
            if (validCategory == null) throw new ArgumentNullException("validCategory");
            if(country == null) throw new ArgumentNullException("country");
            if(caseType == null) throw new ArgumentNullException("caseType");
            if(propertyType == null) throw new ArgumentNullException("propertyType");
            if (subType == null) throw new ArgumentNullException("subType");

            CaseCategoryId = validCategory.CaseCategoryId;
            CountryId = country.Id;
            PropertyTypeId = propertyType.Code;
            CaseTypeId = caseType.Code;
            SubtypeId = subType.Code;
            Country = country;
            PropertyType = propertyType;
            ValidCategory = validCategory;
            CaseType = caseType;
            SubType = subType;
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
        [Column("SUBTYPE")]
        public string SubtypeId { get; set; }

        [MaxLength(50)]
        [Column("SUBTYPEDESC")]
        public string SubTypeDescription { get; set; }

        [Column("SUBTYPEDESC_TID")]
        public int? SubTypeDescriptionTid { get; set; }

        public virtual Country Country { get; protected set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; protected set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; protected set; }
       
        public virtual ValidCategory ValidCategory { get; protected set; }

        [ForeignKey("SubtypeId")]
        public virtual SubType SubType { get; protected set; }
    }
}
