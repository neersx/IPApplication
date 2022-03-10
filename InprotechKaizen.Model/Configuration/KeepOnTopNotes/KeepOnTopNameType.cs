using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Configuration.KeepOnTopNotes
{
    [Table("KOTNAMETYPE")]
    public class KeepOnTopNameType
    {
        [Key]
        [Column("KOTID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int KotTextTypeId { get; set; }

        [Key]
        [MaxLength(3)]
        [Column("NAMETYPE", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public string NameTypeId { get; set; }

        [ForeignKey("NameTypeId")]
        public virtual NameType NameType { get; set; }

        public virtual KeepOnTopTextType KotTextType { get; set; }
    }
}
