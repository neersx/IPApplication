using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEADDRESSSNAP")]
    public class NameAddressSnapshot
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("NAMESNAPNO")]
        public int NameSnapshotId { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }

        [Column("ATTNNAMENO")]
        public int? AttentionNameId { get; set; }

        [Column("ADDRESSCODE")]
        public int? AddressCode { get; set; }

        [Column("REASONCODE")]
        public int? ReasonCode { get; set; }

        [Column("FORMATTEDREFERENCE")]
        public string FormattedReference { get; set; }

        [Column("FORMATTEDNAME")]
        public string FormattedName { get; set; }

        [Column("FORMATTEDADDRESS")]
        public string FormattedAddress { get; set; }

        [Column("FORMATTEDATTENTION")]
        public string FormattedAttention { get; set; }
    }
}