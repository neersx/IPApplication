using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEREPLACED")]
    public class NameReplaced
    {
        public NameReplaced()
        {
        }
        
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("OLDNAMENO")]
        public int OldNameNo { get; set; }
        
        [Column("NEWNAMENO")]
        public int NewNameNo { get; set; }
    }
}