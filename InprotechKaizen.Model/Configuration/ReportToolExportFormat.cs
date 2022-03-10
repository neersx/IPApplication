using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("RPTTOOLEXPORTFMT")]
    public class ReportToolExportFormat
    {

        [Obsolete("For persistence only...")]
        public ReportToolExportFormat()
        {
        }

        [Key]
        [Column("Id")]
        public int Id { get; set; }

        [Column("REPORTTOOL")]
        public int? ReportTool { get; set; }

        [Column("EXPORTFORMAT")]
        public int ExportFormat { get; set; }

        [Column("USEDBYWORKBENCH")]
        public bool UsedByWorkbench { get; set; }

    }
}
