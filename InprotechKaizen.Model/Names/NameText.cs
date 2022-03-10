using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMETEXT")]
    public class NameText
    {
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("NAMENO", Order = 0)]
        public int Id { get; set; }

        [Key]
        [MaxLength(2)]
        [Column("TEXTTYPE", Order = 1)]
        public string TextType { get; set; }

        [Column("TEXT")]
        public string Text { get; set; }

        [Column("TEXT_TID")]
        public int? TextTid { get; set; }
    }
}