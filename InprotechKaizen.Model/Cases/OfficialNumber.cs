using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("OFFICIALNUMBERS")]
    public class OfficialNumber
    {
        [Obsolete("For persistence only.")]
        public OfficialNumber()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public OfficialNumber(NumberType numberType, Case @case, string officialNo)
        {
            if(numberType == null) throw new ArgumentNullException(nameof(numberType));
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if(officialNo == null) throw new ArgumentNullException(nameof(officialNo));

            NumberTypeId = numberType.NumberTypeCode;
            NumberType = numberType;
            Case = @case;
            CaseId = @case.Id;
            Number = officialNo;
        }

        [Key]
        [Column("OFFICIALNUMBERID")]
        public int NumberId { get; set; }

        [Column("CASEID")]
        public int CaseId { get; protected set; }

        [Required]
        [MaxLength(3)]
        [Column("NUMBERTYPE")]
        public string NumberTypeId { get; protected set; }

        [Required]
        [MaxLength(36)]
        [Column("OFFICIALNUMBER")]
        public string Number { get; set; }

        [Column("ISCURRENT")]
        public decimal? IsCurrent { get; set; }

        [Column("DATEENTERED")]
        public DateTime? DateEntered { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
        public virtual Case Case { get; protected set; }

        [ForeignKey("NumberTypeId")]
        public virtual NumberType NumberType { get; protected set; }

        public void MarkAsCurrent()
        {
            IsCurrent = 1;
        }
    }
}