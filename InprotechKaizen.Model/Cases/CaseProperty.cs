using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("PROPERTY")]
    public class CaseProperty
    {
        [Obsolete("For persistence only.")]
        public CaseProperty()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CaseProperty(Case @case, ApplicationBasis basis, Status renewalStatus)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(basis == null) throw new ArgumentNullException("basis");
            if(renewalStatus == null) throw new ArgumentNullException("renewalStatus");

            Case = @case;
            CaseId = @case.Id;
            RenewalStatusId = renewalStatus.Id;
            RenewalStatus = renewalStatus;
            ApplicationBasis = basis;
            Basis = basis.Code;
        }

        [Key]
        [Column("CASEID")]
        [ForeignKey("Case")]
        public int CaseId { get; protected set; }

        [MaxLength(2)]
        [Column("BASIS")]
        public string Basis { get; protected set; }

        [Column("RENEWALSTATUS")]
        public short? RenewalStatusId { get; set; }

        [Column("RENEWALTYPE")]
        public int? RenewalType { get; set; }

        [MaxLength(254)]
        [Column("RENEWALNOTES")]
        public string RenewalNotes { get; set; }

        public virtual Case Case { get; protected set; }

        public virtual Status RenewalStatus { get; protected set; }

        public virtual ApplicationBasis ApplicationBasis { get; protected set; }

        public void SetRenewalStatus(Status renewalStatus)
        {
            RenewalStatus = renewalStatus;
            RenewalStatusId = renewalStatus == null ? (short?)null : renewalStatus.Id;
        }
    }
}