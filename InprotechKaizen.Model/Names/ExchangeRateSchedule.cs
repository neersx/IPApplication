using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("EXCHRATESCHEDULE")]
    public class ExchangeRateSchedule
    {
        public ExchangeRateSchedule()
        {
            
        }

        [Key]
        [Column("EXCHSCHEDULEID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(80)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }
     
        [Required]
        [MaxLength(20)]
        [Column("EXCHSCHEDULECODE")]
        public string ExchangeScheduleCode { get; set; }

    }
}