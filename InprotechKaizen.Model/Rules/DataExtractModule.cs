using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Rules
{
    [Table("DATAEXTRACTMODULE")]
    public class DataExtractModule
    {
        [Obsolete("For persistent purposes")]
        public DataExtractModule()
        {
        }

        [Key]
        [Column("DATAEXTRACTID")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Id { get; set; }

        [Column("SYSTEMID")]
        public short SystemId { get; set; }

        [MaxLength(30)]
        [Column("SITECONTROLID")]
        public string SiteControlId { get; set; }
    }
}