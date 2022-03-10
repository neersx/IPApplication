using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASENAME")]
    public class CaseName
    {
        [Obsolete("For persistence only.")]
        public CaseName()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CaseName(Case @case, NameType nameType, Name name, short sequence)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(nameType == null) throw new ArgumentNullException("nameType");
            if(name == null) throw new ArgumentNullException("name");

            Case = @case;
            CaseId = @case.Id;
            NameType = nameType;
            NameTypeId = nameType.NameTypeCode;
            Name = name;
            NameId = name.Id;
            Sequence = sequence;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CaseName(
            Case @case,
            NameType nameType,
            Name name,
            short sequence,
            Name attentionName = null,
            NameVariant nameVariant = null,
            Address address = null,
            TableCode correspondenceReceived = null)
            : this(@case, nameType, name, sequence)
        {
            AttentionName = attentionName;
            NameVariant = nameVariant;
            Address = address;
            CorrespondenceReceived = correspondenceReceived;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CaseName(
            Case @case,
            NameType nameType,
            Name name,
            short sequence,
            decimal isInherited,
            Name attentionName = null,
            NameVariant nameVariant = null,
            Address address = null,
            TableCode correspondenceReceived = null)
            : this(@case, nameType, name, sequence)
        {
            IsInherited = isInherited;
            AttentionName = attentionName;
            NameVariant = nameVariant;
            Address = address;
            CorrespondenceReceived = correspondenceReceived;
        }

        [Column("CASEID")]
        public int CaseId { get; protected set; }

        [Required]
        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeId { get; protected set; }

        [Column("NAMENO")]
        public int NameId { get; set; }

        [Column("SEQUENCE")]
        public Int16 Sequence { get; set; }

        [MaxLength(80)]
        [Column("REFERENCENO")]
        public string Reference { get; set; }

        [Column("ASSIGNMENTDATE")]
        public DateTime? AssignmentDate { get; set; }

        [Column("COMMENCEDATE")]
        public DateTime? StartingDate { get; set; }

        [Column("EXPIRYDATE")]
        public DateTime? ExpiryDate { get; set; }

        [Column("BILLPERCENTAGE")]
        public decimal? BillingPercentage { get; set; }

        [MaxLength(254)]
        [Column("REMARKS")]
        public string Remarks { get; set; }

        [Column("CORRESPONDNAME")]
        public int? AttentionNameId { get; set; }

        [Column("INHERITED")]
        public decimal? IsInherited { get; set; }

        [Column("INHERITEDNAMENO")]
        public int? InheritedFromNameId { get; set; }

        [MaxLength(3)]
        [Column("INHERITEDRELATIONS")]
        public string InheritedFromRelationId { get; set; }

        [Column("INHERITEDSEQUENCE")]
        public short? InheritedFromSequence { get; set; }

        [Column("CORRESPSENT")]
        public bool? IsCorrespondenceSent { get; set; }

        [Column("DERIVEDCORRNAME")]
        public decimal IsDerivedAttentionName { get; set; }

        [Column("ADDRESSCODE")]
        public int? AddressCode { get; set; }

        [Column("NAMEVARIANTNO")]
        public int? NameVariantId { get; set; }

        public virtual NameType NameType { get; protected set; }

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
        public virtual Case Case { get; protected set; }

        [ForeignKey("NameId")]
        public virtual Name Name { get; protected set; }

        public virtual Address Address { get; protected set; }

        [ForeignKey("AttentionNameId")]
        public virtual Name AttentionName { get; protected set; }

        public virtual NameVariant NameVariant { get; protected set; }

        public virtual TableCode CorrespondenceReceived { get; protected set; }

        public virtual Name InheritedFromName { get; protected set; }
        
        public void SetCorrespondenceReceived(TableCode correspondenceReceived)
        {
            CorrespondenceReceived = correspondenceReceived;
        }
    }
}