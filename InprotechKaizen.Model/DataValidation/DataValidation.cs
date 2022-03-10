using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.DataValidation
{
    [Table("DATAVALIDATION")]
    public class DataValidation
    {
        [Key]
        [Column("VALIDATIONID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("INUSEFLAG")]
        public bool InUseFlag { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("DEFERREDFLAG")]
        public bool DeferredFlag { get; set; }

        [Column("OFFICEID")]
        public int? OfficeId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("FLAGNUMBER")]
        public short? FlagNumber { get; set; }

        [MaxLength(3)]
        [Column("INSTRUCTIONTYPE")]
        public string InstructionType { get; set; }

        [MaxLength(1)]
        [Column("FUNCTIONALAREA")]
        public string FunctionalArea { get; set; }

        [Column("DISPLAYMESSAGE")]
        public string DisplayMessage { get; set; }

        [MaxLength(254)]
        [Column("RULEDESCRIPTION")]
        public string RuleDescription { get; set; }

        [Column("NOTES")]
        public string Notes { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseType { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyType { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("WARNINGFLAG")]
        public bool? IsWarning { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }

        [Column("ROLEID")]
        public int? CanOverrideRoleId { get; set; }

        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [Column("CASECATEGORY")]
        public string CaseCategory { get; set; }

        [Column("SUBTYPE")]
        public string SubType { get; set; }

        [Column("BASIS")]
        public string Basis { get; set; }

        [Column("EVENTNO")]
        public int? EventNo { get; set; }

        [Column("EVENTDATEFLAG")]
        public short? Eventdateflag { get; set; }

        [Column("STATUSFLAG")]
        public short? StatusFlag { get; set; }

        [Column("FAMILYNO")]
        public short? FamilyNo { get; set; }

        [Column("LOCALCLIENTFLAG")]
        public bool? LocalclientFlag { get; set; }

        [Column("USEDASFLAG")]
        public short? UsedasFlag { get; set; }

        [Column("SUPPLIERFLAG")]
        public bool? SupplierFlag { get; set; }

        [Column("CATEGORY")]
        public int? Category { get; set; }

        [Column("NAMETYPE")]
        public string NameType { get; set; }

        [Column("COLUMNNAME")]
        public int? ColumnName { get; set; }

        [Column("ITEM_ID")]
        public int? ItemId { get; set; }

        [Column("PROGRAMCONTEXT")]
        public int? ProgramconText { get; set; }

        [Column("DISPLAYMESSAGE_TID")]
        public int? DisplayMessageTid { get; set; }

        [Column("RULEDESCRIPTION_TID")]
        public int? RuleDescriptionTid { get; set; }

        [Column("NOTES_TID")]
        public int? NotesTid { get; set; }

        [Column("NOTCASETYPE")]
        public bool? NotCaseType { get; set; }

        [Column("NOTCOUNTRYCODE")]
        public bool? NotCountryCode { get; set; }

        [Column("NOTPROPERTYTYPE")]
        public bool? NotPropertyType { get; set; }

        [Column("NOTCASECATEGORY")]
        public bool? NotCaseCategory { get; set; }

        [Column("NOTSUBTYPE")]
        public bool? NotSubtype { get; set; }

        [Column("NOTBASIS")]
        public bool? NotBasis { get; set; }
    }

    public static class DataValidationExtensions
    {
        public static DataValidation ForCase(this DataValidation model)
        {
            model.FunctionalArea = KnownFunctionalArea.Case;
            return model;
        }

        public static DataValidation ForName(this DataValidation model)
        {
            model.FunctionalArea = KnownFunctionalArea.Name;
            return model;
        }
    }
}
