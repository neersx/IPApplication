using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases
{
    [Table("OFFICE")]
    public class Office
    {
        [Obsolete("For persistence only.")]
        public Office()
        {
        }

        public Office(int id, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Office is required.");

            Name = name;
            Id = id;
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("OFFICEID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(80)]
        [Column("DESCRIPTION")]
        public string Name { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? NameTId { get; set; }

        [Column("ORGNAMENO")]
        public int? OrganisationId { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [MaxLength(10)]
        [Column("USERCODE")]
        public string UserCode { get; set; }

        [Column ("LANGUAGECODE")]
        public int? LanguageCode { get; set; }

        [Column ("REGION")]
        public int? RegionCode { get; set; }

        [Column ("RESOURCENO")]
        public int? PrinterCode { get; set; }

        [MaxLength(10)]
        [Column ("CPACODE")]
        public string CpaCode { get; set; }

        [MaxLength(3)]
        [Column ("IRNCODE")]
        public string IrnCode { get; set; }

        [MaxLength(2)]
        [Column ("ITEMNOPREFIX")]
        public string ItemNoPrefix { get; set; }

        [Column ("ITEMNOFROM")]
        public decimal? ItemNoFrom { get; set; }

        [Column ("ITEMNOTO")]
        public decimal? ItemNoTo { get; set; }
        
        [Column ("LASTITEMNO")]
        public decimal? LastItemNo { get; set; }

        [ForeignKey("OrganisationId")]
        public virtual Name Organisation { get; set; }

        [ForeignKey("CountryCode")]
        public virtual Country Country { get; set; }

        [ForeignKey("LanguageCode")]
        public virtual TableCode DefaultLanguage { get; set; }

        [ForeignKey("RegionCode")]
        public virtual TableCode Region { get; set; }

        [ForeignKey("PrinterCode")]
        public virtual Device Printer { get; set; }

        public override string ToString()
        {
            return Name;
        }
    }
}