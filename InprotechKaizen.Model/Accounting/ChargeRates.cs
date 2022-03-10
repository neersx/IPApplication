using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("CHARGERATES")]
    public class ChargeRates
    {
        [Column("CHARGETYPENO")]
        public int ChargeTypeNo { get; set; }

        [Column("RATENO")]
        public int RateNo { get; set; }

        [Column("SEQUENCENO")]
        public int SequenceNo { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("FLAGNUMBER")]
        public short? FlagNumber { get; set; }

        [MaxLength(3)]
        [Column("INSTRUCTIONTYPE")]
        public string InstructionType { get; set; }
    }
}
