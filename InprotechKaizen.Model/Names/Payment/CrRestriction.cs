using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names.Payment
{
    [Table("CRRESTRICTION")]
    public class CrRestriction
    {
        public CrRestriction()
        {
            
        }

        public CrRestriction(int id)
        {
            Id = id;
        }

        [Key]
        [Column("CRRESTRICTIONID")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("CRRESTRICTIONDESC")]
        public string Description { get; set; }
        
        [Column("CRRESTRICTDESC_TID")]
        public int? DescriptionTId { get; set; }

        [Column("ACTIONFLAG")]
        public int? ActionFlag { get; set; }
    }
}