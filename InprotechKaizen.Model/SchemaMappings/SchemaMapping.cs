using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.SchemaMappings
{
    [Table("SCHEMAMAPPINGS")]
    public class SchemaMapping
    {
        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Column("VERSION")]
        public int Version { get; set; }

        [Required]
        [Column("NAME")]
        public string Name { get; set; }

        [Column("CONTENT")]
        public string Content { get; set; }
        
        [Column("ROOTNODE")]
        public string RootNode { get; set; }

        [Column("SCHEMAPACKAGEID")]
        public int SchemaPackageId { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }
        
        [ForeignKey("SchemaPackageId")]
        
        public virtual SchemaPackage SchemaPackage { get; set; }
    }
}