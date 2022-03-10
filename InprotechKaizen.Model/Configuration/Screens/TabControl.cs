
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration.Screens
{
    [Table("TABCONTROL")]
    public class TabControl
    {
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        [Column("TABCONTROLNO", Order = 2)]
        public int Id { get; set; }

        [Key]
        [Column("WINDOWCONTROLNO", Order = 1)]
        public int WindowControlId { get; set; }
        
        [Required]
        [MaxLength(50)]
        [Column("TABNAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("TABTITLE")]
        public string Title { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short DisplaySequence { get; set; }
    }
}
