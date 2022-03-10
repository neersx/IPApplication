using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names.Correspondence
{
    [Table("CORRESPONDTO")]
    public class CorrespondTo
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("CORRESPONDTYPE")]
        public short Id { get; set; }

        [MaxLength(50)]
        [Column("DESCRIPTION")]
        public string Name { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeId { get; set; }

        [MaxLength(3)]
        [Column("COPIESTO")]
        public string CopiesToNameTypeId { get; set; }
    }
}