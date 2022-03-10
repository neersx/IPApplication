using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases
{
    [Table("COUNTRY")]
    public class Country
    {
        [Obsolete("For persistence only.")]
        public Country()
        {
        }

        public Country(string id, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Country is required.");
            if(string.IsNullOrWhiteSpace(id)) throw new ArgumentException("A valid id is required.");

            Name = name;
            Id = id;
        }

        public Country(string id, string name, string type)
        {
            if (string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Country is required.");
            if (string.IsNullOrWhiteSpace(id)) throw new ArgumentException("A valid id is required.");

            Name = name;
            Id = id;
            Type = type;
        }

        [Key]
        [Column("COUNTRYCODE")]
        [MaxLength(3)]
        public string Id { get; set; }

        [MaxLength(60)]
        [Column("COUNTRY")]
        public string Name { get; set; }

        [Column("COUNTRY_TID")]
        public int? NameTId { get; set; }

        [MaxLength(60)]
        [Column("COUNTRYADJECTIVE")]
        public string CountryAdjective { get; set; }

        [Column("POSTCODEFIRST")]
        public decimal? PostCodeFirst { get; set; } 

        [MaxLength(20)]
        [Column("POSTCODELITERAL")]
        public string PostCodeLiteral { get; set; }

        [Column("POSTCODELITERAL_TID")]
        public int? PostCodeLiteralTId { get; set; }

        [MaxLength(60)]
        [Column("POSTALNAME")]
        public string PostalName { get; set; }

        [Column("STATEABBREVIATED")]
        public decimal? StateAbbreviated { get; set; }

        [Column("ADDRESSSTYLE")]
        [ForeignKey("AddressStyle")]
        public int? AddressStyleId { get; set; }

        public virtual TableCode AddressStyle { get; set; }

        [Column("NAMESTYLE")]
        [ForeignKey("NameStyle")]
        public int? NameStyleId { get; set; }

        public virtual TableCode NameStyle { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("ALLMEMBERSFLAG")]
        public decimal AllMembersFlag { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1721:PropertyNamesShouldNotMatchGetMethods")]
        [Column("RECORDTYPE")]
        [MaxLength(1)]
        public string Type { get; set; }

        [MaxLength(3)]
        [Column("ALTERNATECODE")]
        public string AlternateCode { get; set; }

        [MaxLength(10)]
        [Column("COUNTRYABBREV")]
        public string Abbreviation { get; set; }

        [MaxLength(60)]
        [Column("INFORMALNAME")]
        public string InformalName { get; set; }

        [MaxLength(5)]
        [Column("ISD")]
        public string IsdCode { get; set; }

        [Column("PRIORARTFLAG")]
        public bool? ReportPriorArt { get; set; }

        [MaxLength(254)]
        [Column("NOTES")]
        public string Notes { get; set; }

        [Column("DATECOMMENCED")]
        public DateTime? DateCommenced { get; set; }

        [Column("DATECEASED")]
        public DateTime? DateCeased { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "WorkDay")]
        [Column("WORKDAYFLAG")]
        public short? WorkDayFlag { get; set; }

        public virtual ICollection<State> States { get; set; } = new Collection<State>();

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flags")]
        public virtual ICollection<CountryFlag> CountryFlags { get; set; } = new Collection<CountryFlag>();

        [Column("INFORMALNAME_TID")]
        public int? InformalNameTId { get; set; }

        [Column("COUNTRYADJECTIVE_TID")]
        public int? CountryAdjectiveTId { get; set; }

        [Column("POSTALNAME_TID")]
        public int? PostalNameTId { get; set; }
        
        [Column("NOTES_TID")]
        public int? NotesTId { get; set; }

        [MaxLength(20)]
        [Column("STATELITERAL")]
        public string StateLabel { get; set; }

        [Column("STATELITERAL_TID")]
        public int? StateLabelTId { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("POSTCODEAUTOFLAG")]
        public decimal? PostCodeAutoFlag { get; set; }

        [Column("POSTCODESEARCHCODE")]
        [ForeignKey("PostCodeSearchCode")]
        public int? PostCodeSearchCodeId { get; set; }

        public virtual TableCode PostCodeSearchCode { get; set; }

        [Column("DEFAULTTAXCODE")]
        [ForeignKey("DefaultTaxRate")]
        [MaxLength(3)]
        public string DefaultTaxId { get; set; }

        public virtual TaxRate DefaultTaxRate { get; set; }

        [Column("DEFAULTCURRENCY")]
        [ForeignKey("DefaultCurrency")]
        [MaxLength(3)]
        public string DefaultCurrencyId { get; set; }

        public virtual Currency DefaultCurrency { get; set; } 

        [Column("REQUIREEXEMPTTAXNO")]
        public decimal? TaxNoMandatory { get; set; }
        
        public override string ToString()
        {
            return Name;
        }

        public bool IsGroup => KnownJurisdictionTypes.GetType(Type) == KnownJurisdictionTypes.GetType("1");

        public bool IsInternal => KnownJurisdictionTypes.GetType(Type) == KnownJurisdictionTypes.GetType("2");

        public bool IsTaxNumberMandatory => TaxNoMandatory.HasValue && TaxNoMandatory > 0;
    }
}