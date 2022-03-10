using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEIMAGE")]
    public class NameImage
    {
        public NameImage()
        {
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("NAMENO")]
        public int Id { get; set; }

        [Column("IMAGEID")]
        public int ImageId { get; set; }

        [Column("IMAGETYPE")]
        public int? ImageType { get; set; }

        [Column("IMAGESEQUENCE")]
        public short? ImageSequence { get; set; }

        [MaxLength(254)]
        [Column("NAMEIMAGEDESC")]
        public string NameImageDesc { get; set; }
    }
}

