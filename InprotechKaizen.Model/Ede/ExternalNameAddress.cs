using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EXTERNALNAMEADDRESS")]
    public class ExternalNameAddress
    {
        [Key]
        [Column("EXTERNALNAMEADDRESSID")]
        public int Id { get; set; }

        [MaxLength(2000)]
        [Column("ADDRESS")]
        public string Address { get; set; }

        [MaxLength(254)]
        [Column("CITY")]
        public string City { get; set; }

        [MaxLength(50)]
        [Column("STATE")]
        public string State { get; set; }

        [MaxLength(50)]
        [Column("POSTCODE")]
        public string PostCode { get; set; }

        [MaxLength(3)]
        [Column("COUNTRY")]
        public string Country { get; set; }
    }
}