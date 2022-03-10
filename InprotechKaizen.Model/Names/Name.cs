using InprotechKaizen.Model.Cases;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("NAME")]
    public class Name
    {
        [Obsolete("For persistence only.")]
        public Name()
        {
        }

        public Name(int nameId)
        {
            Id = nameId;
        }

        [Key]
        [Column("NAMENO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; protected set; }

        [MaxLength(20)]
        [Column("NAMECODE")]
        public string NameCode { get; set; }

        [Required]
        [MaxLength(254)]
        [Column("NAME")]
        public string LastName { get; set; }

        [MaxLength(20)]
        [Column("TITLE")]
        public string Title { get; set; }

        [MaxLength(50)]
        [Column("FIRSTNAME")]
        public string FirstName { get; set; }

        [Column("SUPPLIERFLAG")]
        public decimal? SupplierFlag { get; set; }

        [MaxLength(50)]
        [Column("MIDDLENAME")]
        public string MiddleName { get; set; }

        [MaxLength(20)]
        [Column("SUFFIX")]
        public string Suffix { get; set; }

        [MaxLength(10)]
        [Column("INITIALS")]
        public string Initials { get; set; }

        [Column("NAMESTYLE")]
        public int? NameStyle { get; set; }

        [Column("USEDASFLAG")]
        public short UsedAs { get; set; }

        [Column("DATECEASED")]
        public DateTime? DateCeased { get; set; }

        [Column("POSTALADDRESS")]
        public int? PostalAddressId { get; set; }

        [Column("STREETADDRESS")]
        public int? StreetAddressId { get; set; }

        [Column("MAINPHONE")]
        public int? MainPhoneId { get; set; }

        [Column("FAX")]
        public int? MainFaxId { get; set; }

        [Column("MAINCONTACT")]
        public int? MainContactId { get; set; }

        [Column("MAINEMAIL")]
        public int? MainEmailId { get; set; }

        [MaxLength(20)]
        [Column("SEARCHKEY1")]
        public string SearchKey1 { get; set; }

        [MaxLength(20)]
        [Column("SEARCHKEY2")]
        public string SearchKey2 { get; set; }

        [MaxLength(254)]
        [Column("REMARKS")]
        public string Remarks { get; set; }

        [Column("DATECHANGED")]
        public DateTime? DateChanged { get; set; }

        [MaxLength(30)]
        [Column("TAXNO")]
        public string TaxNumber { get; set; }

        [Column("DATEENTERED")]
        public DateTime? DateEntered { get; set; }

        [MaxLength(10)]
        [Column("SOUNDEX")]
        public string Soundex { get; set; }

        public bool IsStaff => Convert.ToBoolean(UsedAs & NameUsedAs.StaffMember);

        public bool IsOrganisation => !IsIndividual;

        public bool IsIndividual => Convert.ToBoolean(UsedAs & NameUsedAs.Individual);

        public bool IsClient => Convert.ToBoolean(UsedAs & NameUsedAs.Client);

        public virtual ICollection<NameTypeClassification> NameTypeClassifications { get; protected set; } = new Collection<NameTypeClassification>();

        public virtual ICollection<NameVariant> NameVariants { get; protected set; } = new Collection<NameVariant>();

        public virtual ICollection<NameAddress> Addresses { get; protected set; } = new Collection<NameAddress>();

        public virtual ICollection<NameTelecom> Telecoms { get; protected set; } = new Collection<NameTelecom>();

        public virtual ClientDetail ClientDetail { get; set; }

        public virtual Country Nationality { get; set; }

        public virtual Name MainContact { get; set; }

        public virtual Individual Individual { get; set; }

        public virtual Organisation Organisation { get; set; }

        public virtual Locality Locality { get; set; }

        public virtual NameFamily NameFamily { get; set; }
    }
}