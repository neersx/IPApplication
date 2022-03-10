using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.SchemaMappings
{
    [Table("SCHEMAFILES")]
    public class SchemaFile
    {
        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Required]
        [Column("NAME")]
        public string Name { get; set; }

        [Required]
        [Column("CONTENT")]
        public string Content { get; set; }
        
        [Column("ISMAPPABLE")]
        public bool IsMappable { get; set; }

        [Column("SCHEMAPACKAGEID")]
        public int? SchemaPackageId { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        [ForeignKey("SchemaPackageId")]
        public virtual SchemaPackage SchemaPackage { get; set; }
    }
}