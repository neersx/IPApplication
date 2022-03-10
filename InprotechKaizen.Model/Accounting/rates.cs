using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("RATES")]
    public class Rates
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("RATENO")]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        [Column("RATEDESC")]
        public string RateDescription { get; set; }

        [Column("RATEDESC_TID")]
        public int? RateDescTId { get; set; }
    }
}
