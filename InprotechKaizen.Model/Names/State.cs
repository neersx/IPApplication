using System;
using System.ComponentModel.DataAnnotations;
using InprotechKaizen.Model.Cases;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("STATE")]
    public class State
    {

        public State() { }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public State(string code, string name, Country country)
        {
            if (country == null) throw new ArgumentNullException(nameof(country));

            Code = code;
            Name = name;
            Country = country;
            CountryCode = country.Id;
        }

        public State(string code, string name, string countryCode)
        {
            Code = code;
            Name = name;
            CountryCode = countryCode;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Key]
        [MaxLength(3)]
        [Column("COUNTRYCODE", Order = 1)]
        public string CountryCode { get; set; }

        [Key]
        [MaxLength(20)]
        [Column("STATE", Order = 2)]
        public string Code { get; set; }

        [MaxLength(40)]
        [Column("STATENAME")]
        public string Name { get; set; }

        [Column("STATENAME_TID")]
        public int? NameTId { get; set; }

        public virtual Country Country { get; protected set; }
    }
}
