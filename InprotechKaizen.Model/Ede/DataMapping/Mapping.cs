using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede.DataMapping
{
    [Table("MAPPING")]
    public class Mapping
    {
        [Key]
        [Column("ENTRYID")]
        public int Id { get; set; }

        [Column("STRUCTUREID")]
        public short StructureId { get; set; }
        
        [MaxLength(50)]
        [Column("INPUTCODE")]
        public string InputCode { get; set; }

        [MaxLength(254)]
        [Column("INPUTDESCRIPTION")]
        public string InputDescription { get; set; }
        
        [Column("INPUTCODEID")]
        public int? InputCodeId { get; set; }
        
        [Column("OUTPUTCODEID")]
        public int? OutputCodeId { get; set; }
        
        [MaxLength(50)]
        [Column("OUTPUTVALUE")]
        public string OutputValue { get; set; }

        [Column("DATASOURCEID")]
        public int? DataSourceId { get; set; }

        [Column("ISNOTAPPLICABLE")]
        public bool IsNotApplicable { get; set; }

        [ForeignKey("InputCodeId")]
        public virtual EncodedValue InputEncodedValue { get; set; }

        [ForeignKey("OutputCodeId")]
        public virtual EncodedValue OutputEncodedValue { get; set; }

        [ForeignKey("StructureId")]
        public virtual MapStructure MapStructure { get; set; }

        [ForeignKey("DataSourceId")]
        public virtual DataSource DataSource { get; set; }
    }
}
