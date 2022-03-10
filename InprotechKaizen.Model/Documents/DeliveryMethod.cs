using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("DELIVERYMETHOD")]
    public class DeliveryMethod
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("DELIVERYID")]
        public short Id { get; set; }

        [Column("DELIVERYTYPE")]
        public int Type { get; set; }
        
        [MaxLength(254)]
        [Column("FILEDESTINATION")]
        public string FileDestination { get; set; }

        [MaxLength(60)]
        [Column("DESTINATIONSP")]
        public string DestinationStoredProcedure { get; set; }

        [MaxLength(60)]
        [Column("EMAILSP")]
        public string EmailStoredProcedure { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }
    }
}