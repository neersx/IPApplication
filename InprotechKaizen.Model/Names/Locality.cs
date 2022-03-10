using InprotechKaizen.Model.Cases;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("AIRPORT")]
    public class Locality
    {
        [Obsolete("For persistence only.")]
        public Locality()
        {
        }

        public Locality(string code, string name)
        {
            Code = code;
            Name = name;
        }

        public Locality(string code, string name, string city)
        {
            Code = code;
            Name = name;
            City = city;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Locality(string code, string name, string city, State state, Country country)
        {
            Code = code;
            Name = name;
            City = city;
            State = state;
            Country = country;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [Column("AIRPORTCODE")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [MaxLength(5)]
        public string Code { get; set; }

        [MaxLength(30)]
        [Column("AIRPORTNAME")]
        public string Name { get; set; }

        [Column("AIRPORTNAME_TID")]
        public int? NameTId { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [MaxLength(20)]
        [Column("STATE")]
        public string StateCode { get; set; }

        [MaxLength(30)]
        [Column("CITY")]
        public string City { get; set; }

        [Column("CITY_TID")]
        public int? CityTId { get; set; }

        public virtual Country Country { get; protected set; }

        public virtual State State { get; protected set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }
    }
}
