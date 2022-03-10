using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("IMPORTANCE")]
    public class Importance
    {
        public Importance()
        {

        }

        public Importance(string id, string description)
        {
            Level = id;
            Description = description;
        }

        [Key]
        [Column("IMPORTANCELEVEL")]
        [MaxLength(2)]
        [Required]
        public string Level { get; set; }

        [Column("IMPORTANCEDESC")]
        [MaxLength(30)]
        public string Description { get; set; }

        [Column("IMPORTANCEDESC_TID")]
        public int? DescriptionTId { get; set; }

        [NotMapped]
        public int? LevelNumeric
        {
            get
            {
                if (int.TryParse(Level, out var l))
                    return l;
                return null;

            }
        }
    }
}