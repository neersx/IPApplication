using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Names
{
    [Table("ADDRESS")]
    public class Address
    {
        [Obsolete("For persistence only.")]
        public Address()
        {
        }

        public Address(int addressId)
        {
            Id = addressId;
        }

        [Key]
        [Column("ADDRESSCODE")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get;  set; }

        [MaxLength(254)]
        [Column("STREET1")]
        public string Street1 { get; set; }

        [MaxLength(254)]
        [Column("STREET2")]
        public string Street2 { get; set; }

        [MaxLength(30)]
        [Column("CITY")]
        public string City { get; set; }

        [MaxLength(20)]
        [Column("STATE")]
        public string State { get; set; }

        [MaxLength(10)]
        [Column("POSTCODE")]
        public string PostCode { get; set; }

        [Column("TELEPHONE")]
        public int? Telephone { get; set; }

        [Column("FAX")]
        public int? Fax { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        public virtual Country Country { get; set; }
    }
}