using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EXTERNALNAME")]
    public class ExternalName
    {
        [Key]
        [Column("EXTERNALNAMEID")]
        public int Id { get; set; }

        [Column("DATASOURCENAMENO")]
        public int DataSourceNameId { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameType { get; set; }

        [MaxLength(254)]
        [Column("EXTERNALNAME")]
        public string ExtName { get; set; }
        
        [MaxLength(50)]
        [Column("EXTERNALNAMECODE")]
        public string ExternalNameCode { get; set; }

        [MaxLength(254)]
        [Column("EMAIL")]
        public string Email { get; set; }

        [MaxLength(100)]
        [Column("PHONE")]
        public string Phone { get; set; }
        
        [MaxLength(100)]
        [Column("FAX")]
        public string Fax { get; set; }

        [Column("ENTITYTYPEFLAG")]
        public int EntityType { get; set; }

        [MaxLength(50)]
        [Column("FIRSTNAME")]
        public string FirstName { get; set; }

        public virtual ExternalNameAddress ExternalNameAddress { get; set; }
    }
}
