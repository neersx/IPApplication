using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDEUNRESOLVEDNAME")]
    public class EdeUnresolvedName
    {
        [Key]
        [Column("UNRESOLVEDNAMENO")]
        public int Id { get; set; }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameType { get; set; }

        [MaxLength(50)]
        [Column("SENDERNAMEIDENTIFIER")]
        public string SenderNameIdentifier { get; set; }

        [MaxLength(50)]
        [Column("FIRSTNAME")]
        public string FirstName { get; set; }

        [MaxLength(254)]
        [Column("NAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("ATTNFIRSTNAME")]
        public string AttentionFirstName { get; set; }

        [MaxLength(254)]
        [Column("ATTNLASTNAME")]
        public string AttentionLastName { get; set; }

        [MaxLength(10)]
        [Column("ATTNTITLE")]
        public string AttentionTitle { get; set; }

        [MaxLength(100)]
        [Column("PHONE")]
        public string Phone { get; set; }

        [MaxLength(100)]
        [Column("FAX")]
        public string Fax { get; set; }

        [MaxLength(254)]
        [Column("EMAIL")]
        public string Email { get; set; }

        [Column("ENTITYTYPEFLAG")]
        public int EntityType { get; set; }

        [MaxLength(1000)]
        [Column("ADDRESSLINE")]
        public string AddressLine { get; set; }

        [MaxLength(254)]
        [Column("CITY")]
        public string City { get; set; }

        [MaxLength(50)]
        [Column("POSTCODE")]
        public string PostCode { get; set; }

        [MaxLength(50)]
        [Column("STATE")]
        public string State { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }
    }
}
