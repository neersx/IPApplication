using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Documents;

namespace InprotechKaizen.Model.Rules
{
    [Table("DETAILLETTERS")]
    public class DocumentRequirement
    {
        [Obsolete("For persistence only.")]
        public DocumentRequirement()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public DocumentRequirement(
            Criteria criteria,
            DataEntryTask dataEntryTask,
            Document document,
            bool isMandatory = false)
        {
            if (criteria == null) throw new ArgumentNullException("criteria");
            if (dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if (document == null) throw new ArgumentNullException("document");

            CriteriaId = criteria.Id;
            DataEntryTaskId = dataEntryTask.Id;
            DocumentId = document.Id;
            Document = document;
            InternalMandatoryFlag = isMandatory ? 1 : 0;
        }

        [Column("CRITERIANO", Order = 0)]
        [Key]
        public int CriteriaId { get; protected set; }

        [Column("ENTRYNUMBER", Order = 1)]
        [Key]
        public short DataEntryTaskId { get; protected set; }

        [Column("LETTERNO", Order = 2)]
        [Key]
        public short DocumentId { get; internal set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("MANDATORYFLAG")]
        public decimal? InternalMandatoryFlag { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("DELIVERYMETHODFLAG")]
        public decimal? DeliveryMethodFlag { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        public virtual Document Document { get; protected set; }

        public bool IsMandatory => InternalMandatoryFlag.HasValue && InternalMandatoryFlag.Value > 0M;

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }
    }

    public static class DocumentRequirementExt
    {
        public static DocumentRequirement InheritRuleFrom(this DocumentRequirement documentRequirement, DocumentRequirement from)
        {
            if (documentRequirement == null) throw new ArgumentNullException(nameof(documentRequirement));
            if (from == null) throw new ArgumentNullException(nameof(from));

            documentRequirement.DocumentId = from.DocumentId;
            documentRequirement.IsInherited = true;
            documentRequirement.CopyFrom(from);
            return documentRequirement;
        }

        static void CopyFrom(this DocumentRequirement documentRequirement, DocumentRequirement from)
        {
            documentRequirement.InternalMandatoryFlag = from.InternalMandatoryFlag;
            documentRequirement.DeliveryMethodFlag = from.DeliveryMethodFlag;
        }
    }
}