using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.SchemaMapping.Migration.Models
{
    [Table("SchemaFiles")]
    public class ObsoleteSchemaFile
    {
        public int Id { get; set; }

        public string Name { get; set; }

        public Guid MetadataId { get; set; }

        public bool IsMappable { get; set; }

        public int? SchemaPackageId { get; set; }

        public DateTime CreatedOn { get; set; }

        public DateTime UpdatedOn { get; set; }

        public virtual ObsoleteSchemaPackage ObsoleteSchemaPackage { get; set; }
    }
}