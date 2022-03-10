using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    [Table("DATASOURCE")]
    public class DataSource
    {
        [Key]
        [Column("DATASOURCEID")]
        public int Id { get; set; }

        [Column("SYSTEMID")]
        public short SystemId { get; set; }

        [Column("SOURCENAMENO")]
        public int? SourceNameNo{ get; set; }

        [Column("ISPROTECTED")]
        public bool IsProtected { get; set; }
        
        [MaxLength(30)]
        [Column("DATASOURCECODE")]
        public string DataSourceCode { get; set; }
    }
}