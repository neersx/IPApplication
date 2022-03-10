using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    [Table("DATAMAP")]
    public class DataMap
    {
        [Key]
        [Column("MAPNO")]
        public int MapNo { get; set; }

        [Column("SOURCENO")]
        public int SourceNo { get; set; }
    }
}
