using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.SchemaMapping.Migration.Models
{
    [Table("SchemaPackages")]
    public class ObsoleteSchemaPackage
    {
        public int Id { get; set; }

        public string Name { get; set; }

        public bool IsValid { get; set; }

        public DateTime CreatedOn { get; set; }

        public DateTime UpdatedOn { get; set; }
    }
}