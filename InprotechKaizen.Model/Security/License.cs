using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Inprotech.Infrastructure.Security.Licensing;

namespace InprotechKaizen.Model.Security
{
    [Table("LICENSEMODULE")]
    public class License
    {
        [Obsolete("For Persistent Only")]
        public License()
        {
            
        }

        public License(LicensedModule licensedModule)
        {
            Id = (int) licensedModule;
        }

        [Key]
        [Column("MODULEID")]
        public int Id { get; set; }

        [Column("MODULENAME")]
        public string Name { get; set; }
    }
}
