using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.SchemaMapping.Migration.Models
{
    [Table("SchemaMappings")]
    public class ObsoleteSchemaMapping
    {        
        public int Id { get; set; }

        public int Version { get; set; }

        public string Name { get; set; }

        public int SchemaPackageId { get; set; }

        public string Content { get; set; }

        public DateTime CreatedOn { get; set; }

        public DateTime UpdatedOn { get; set; }

        public string RootNode { get; set; }

        public virtual ObsoleteSchemaPackage ObsoleteSchemaPackage { get; set; }
    }
}