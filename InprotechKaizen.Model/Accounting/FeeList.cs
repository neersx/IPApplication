using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("FEELIST")]
    public class FeeList
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int FeeListNo { get; set; }

        [Required]
        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [MaxLength(50)]
        [Column("FEELISTDESC")]
        public string FeeListDescription { get; set; }

        [Column("DATEPRINTED")]
        public DateTime? DatePrinted { get; set; }

        [MaxLength(9)]
        [Column("BATCHNUMBER")]
        public string BatchId { get; set; }

        [Column("REGISTEREDFLAG")]
        public decimal? IsRegistered { get; set; }

        [MaxLength(3)]
        [Column("CURRENCY")]
        public string Currency { get; set; }

        [Column("TAXABLE")]
        public decimal? IsTaxable { get; set; }

        [Column("OFFICEID")]
        public int? OfficeId { get; set; }

        [Column("FEELISTNAME")]
        public int? FeeListNameId { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [MaxLength(2)]
        [Column("CASECATEGORY")]
        public string CaseCategoryId { get; set; }

        [Column("IPOFFICE")]
        public int? IPOfficeId { get; set; }
    }
}