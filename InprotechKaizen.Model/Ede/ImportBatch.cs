using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("IMPORTBATCH")]
    public class ImportBatch
    {
        [Key]
        [Column("IMPORTBATCHNO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int BatchId { get; set; }

        [Column("BATCHTYPE")]
        public int? BatchType { get; set; }

        [Column("IMPORTEDDATE")]
        public DateTime? ImportedDate { get; set; }

        [MaxLength(2000)]
        [Column("BATCHNOTES")]
        public string Notes { get; set; }

        [Column("FROMNAMENO")]
        public int? FromNameId { get; set; }
    }
}