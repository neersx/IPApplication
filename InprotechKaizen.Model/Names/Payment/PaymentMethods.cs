using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names.Payment
{
    [Table("PAYMENTMETHODS")]
    public class PaymentMethods
    {
        public PaymentMethods()
        {
            
        }

        public PaymentMethods(int id)
        {
            Id = id;
        }

        [Key]
        [Column("PAYMENTMETHOD")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("PAYMENTDESCRIPTION")]
        public string Description { get; set; }
        
        [Column("PAYMENTDESC_TID")]
        public int? DescriptionTId { get; set; }

        [Column("PRESENTPHYSICALLY")]
        public int PresentPhysically { get; set; }
        
        [Column("USEDBY")]
        public int? UsedBy { get; set; }
    }
}