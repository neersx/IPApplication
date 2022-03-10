using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.SchemaMappings
{
    [Table("SCHEMAPACKAGES")]
    public class SchemaPackage
    {
        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Required]
        [Column("NAME")]
        public string Name { get; set; }

        [Column("ISVALID")]
        public bool IsValid { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }
    }
}