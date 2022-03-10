using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Queries
{
    [Table("QUERYDATAITEM")]
    public class QueryDataItem
    {
        [Key]
        [Column("DATAITEMID", Order = 1)]
        public int DataItemId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("PROCEDURENAME")]
        public string ProcedureName { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("PROCEDUREITEMID")]
        public string ProcedureItemId { get; set; }

        [Column("ISMULTIRESULT")]
        public bool IsMultiResult { get; set; }

        [Column("DATAFORMATID")]
        public int DataFormatId { get; set; }

        [Column("DECIMALPLACES")]
        public byte? DecimalPlaces { get; set; }

        [MaxLength(50)]
        [Column("FORMATITEMID")]
        public string FormatItemId { get; set; }

        [Column("QUALIFIERTYPE")]
        public short? QualifierType { get; set; }

        [MaxLength(1)]
        [Column("SORTDIRECTION")]
        public string SortDirection { get; set; }
    }
}
