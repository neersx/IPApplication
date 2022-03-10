using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ValidCombinations;

namespace InprotechKaizen.Model.Cases
{
    [Table("VALIDATENUMBERS")]
    public class CountryValidNumber
    {
        [Obsolete("For persistence only...")]
        public CountryValidNumber()
        {
        }

        public CountryValidNumber(int id, string propertyId, string numberType, string countryCode, string pattern, string errorMessage)
        {
            Id = id;
            PropertyId = propertyId;
            NumberTypeId = numberType;
            CountryId = countryCode;
            Pattern = pattern;
            ErrorMessage = errorMessage;
        }

        [Key]
        [Column("VALIDATIONID")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [Required]
        [MaxLength(254)]
        [Column("PATTERN")]
        public string Pattern { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("WARNINGFLAG")]
        public decimal WarningFlag { get; set; }

        [Required]
        [MaxLength(254)]
        [Column("ERRORMESSAGE")]
        public string ErrorMessage { get; set; }

        [Required]
        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyId { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [MaxLength(2)]
        [Column("CASECATEGORY")]
        public string CaseCategoryId { get; set; }

        [MaxLength(2)]
        [Column("SUBTYPE")]
        public string SubTypeId { get; set; }

        [Required]
        [MaxLength(3)]
        [Column("NUMBERTYPE")]
        public string NumberTypeId { get; set; }

        [Column("VALIDFROM")]
        public DateTime? ValidFrom { get; set; }

        [Column("ERRORMESSAGE_TID")]
        public int? ErrorMessageTId { get; set; }

        [Column("VALIDATINGSPID")]
        [ForeignKey("AdditionalValidation")]
        public int? AdditionalValidationId { get; set; }

        public virtual TableCode AdditionalValidation { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Property")]
        public virtual PropertyType Property { get; set; }

        public virtual ValidProperty ValidProperty { get; set; }

        public virtual NumberType NumberType { get; set; }

        public virtual CaseType CaseType { get; set; }

        public virtual SubType SubType { get; set; }

        public virtual CaseCategory CaseCategory { get; set; }

        public virtual ValidSubType ValidSubType { get; set; }

        public virtual ValidCategory ValidCaseCategory { get; set; }
    }
}