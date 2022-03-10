using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMELOCATION")]
    public class NameLocation
    {
        [Key]
        [Column("NAMENO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int NameId { get; set; }

        [Key]
        [Column("FILELOCATION", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int FileLocationId { get; set; }

        [Column("ISCURRENTLOCATION")]
        public bool? IsCurrentLocation { get; set; }

        [Column("ISDEFAULTLOCATION")]
        public bool? IsDefaultLocation { get; set; }
    }
}