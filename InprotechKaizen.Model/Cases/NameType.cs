using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases
{
    [Table("NAMETYPE")]
    public class NameType
    {
        [Obsolete("For persistence only.")]
        public NameType()
        {
        }

        public NameType(int id, string nameTypeCode, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Name Type is required.");
            if(string.IsNullOrWhiteSpace(nameTypeCode)) throw new ArgumentException("A valid nameTypeId is required.");

            Id = id;
            Name = name;
            NameTypeCode = nameTypeCode;
        }

        public NameType(string nameTypeCode, string name)
        {
            if (string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Name Type is required.");
            if (string.IsNullOrWhiteSpace(nameTypeCode)) throw new ArgumentException("A valid nameTypeId is required.");

            Name = name;
            NameTypeCode = nameTypeCode;
        }

        public NameType(string nameTypeCode, string name, short? picklistFlags) : this(nameTypeCode, name)
        {
            PickListFlags = picklistFlags;
        }

        [Column("NAMETYPEID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Key]
        [Column("NAMETYPE")]
        [MaxLength(3)]
        public string NameTypeCode { get; set; }
        
        [MaxLength(50)]
        [Column("DESCRIPTION")]
        public string Name { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? NameTId { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("COLUMNFLAGS")]
        public short? ColumnFlag { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flags")]
        [Column("PICKLISTFLAGS")]
        public short? PickListFlags { get; set; }

        [Column("MAXIMUMALLOWED")]
        public short? MaximumAllowed { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("MANDATORYFLAG")]
        public decimal? MandatoryFlag { get; set; }

        [MaxLength(3)]
        [Column("FUTURENAMETYPE")]
        public string FutureNameType { get; set; }

        [MaxLength(3)]
        [Column("OLDNAMETYPE")]
        public string OldNameType { get; set; }

        [Column("SHOWNAMECODE")]
        public decimal? ShowNameCode { get; set; }

        [Column("NAMERESTRICTFLAG")]
        public decimal? IsNameRestricted { get; set; }

        [MaxLength(3)]
        [Column("PATHNAMETYPE")]
        public string PathNameType { get; set; }

        [MaxLength(3)]
        [Column("PATHRELATIONSHIP")]
        public string PathRelationship { get; set; }

        [MaxLength(2)]
        [Column("KOTTEXTTYPE")]
        public string KotTextType { get; set; }

        [Column("PROGRAM")]
        public int? Program { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("HIERARCHYFLAG")]
        public decimal? HierarchyFlag { get; set; }

        [Column("USEHOMENAMEREL")]
        public bool UseHomeNameRelationship { get; set; }

        [Column("UPDATEFROMPARENT")]
        public bool UpdateFromParent { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("KEEPSTREETFLAG")]
        public decimal? KeepStreetFlag { get; set; }

        [Column("NATIONALITYFLAG")]
        public bool NationalityFlag { get; set; }

        [Column("CHANGEEVENTNO")]
        public int? ChangeEventNo { get; set; }

        [Column("DEFAULTNAMENO")]
        public int? DefaultNameId { get; set; }

        [Column("ETHICALWALL")]
        public byte EthicalWall { get; set; }

        [Column("PRIORITYORDER")]
        public short PriorityOrder { get; set; }

        public virtual NameRelation PathNameRelation { get; set; }

        public virtual Event ChangeEvent { get; set; }

        public virtual Name DefaultName { get; set; }

        public virtual TextType TextType { get; set; }

        public bool IsAttentionDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayAttention);

        public bool IsAddressDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayAddress);

        public bool IsReferenceNumberDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayReferenceNumber);

        public bool IsAssignDateDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayAssignDate);

        public bool IsDateCommencedDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayDateCommenced);

        public bool IsDateCeasedDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayDateCeased);

        public bool IsBillPercentDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayBillPercentage);

        public bool IsInheritedDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayInherited);

        public bool IsStandardNameDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayStandardName);

        public bool IsNameVariantDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayNameVariant);

        public bool IsRemarksDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayRemarks);

        public bool IsCorrespondenceDisplayed => Convert.ToBoolean(ColumnFlag & KnownNameTypeColumnFlags.DisplayCorrespondence);
        
        public bool IsEnforceNameRestriction => IsNameRestricted.GetValueOrDefault() == 1;

        public bool IsNameStreetSaved => KeepStreetFlag.GetValueOrDefault() == 1;

        public bool IsClassified => Convert.ToBoolean(PickListFlags & KnownNameTypeAllowedFlags.SameNameType);

        public bool AllowStaffNames => Convert.ToBoolean(PickListFlags & KnownNameTypeAllowedFlags.StaffNames);

        public bool AllowOrganisationNames => Convert.ToBoolean(PickListFlags & KnownNameTypeAllowedFlags.Organisation);

        public bool AllowIndividualNames => Convert.ToBoolean(PickListFlags & KnownNameTypeAllowedFlags.Individual);

        public bool AllowClientNames => Convert.ToBoolean(PickListFlags & KnownNameTypeAllowedFlags.Client);

        public bool AllowCrmNames => Convert.ToBoolean(PickListFlags & KnownNameTypeAllowedFlags.CrmNameType);

        public bool AllowSuppliers => Convert.ToBoolean(PickListFlags & KnownNameTypeAllowedFlags.Supplier);

        public bool IsUnrestricted => !IsClassified;

        public bool IsMandatory => MandatoryFlag.HasValue && MandatoryFlag.Value == 1m;

        public bool UseNameType => HierarchyFlag.HasValue && HierarchyFlag.Value == 1m;

        public bool UpdateFromParentNameType => UpdateFromParent && !string.IsNullOrEmpty(PathNameType);
    }
}