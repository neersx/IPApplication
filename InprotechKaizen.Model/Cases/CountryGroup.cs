using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("COUNTRYGROUP")]
    public class CountryGroup
    {

        [Obsolete("For persistence only.")]
        public CountryGroup()
        {
        }

        public CountryGroup(string id, string countryCode)
        {
            if(id == null) throw new ArgumentNullException("id");
            if(countryCode == null) throw new ArgumentNullException("countryCode");

            Id = id;
            MemberCountry = countryCode;
        }

        public CountryGroup(Country groupCountry, Country memberCountry)
        {
            if (groupCountry == null) throw new ArgumentNullException("groupCountry");
            if (memberCountry == null) throw new ArgumentNullException("memberCountry");
     
            Id = groupCountry.Id;
            GroupCountry = groupCountry;
            MemberCountry = memberCountry.Id;
            GroupMember = memberCountry;
        }

        [Key]
        [MaxLength(3)]
        [Column("TREATYCODE", Order = 0)]
        public string Id { get; protected set; }

        [Key]
        [MaxLength(3)]
        [Column("MEMBERCOUNTRY", Order = 1)]
        public string MemberCountry { get; protected set; }

        [MaxLength(100)]
        [Column("PROPERTYTYPES")]
        public string PropertyTypes { get; set; }

        [Column("DATECOMMENCED")]
        public DateTime? DateCommenced { get; set; }

        [Column("DATECEASED")]
        public DateTime? DateCeased { get; set; }

        [Column("ASSOCIATEMEMBER")]
        public decimal? AssociateMember { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("DEFAULTFLAG")]
        public decimal? DefaultFlag { get; set; }

        [Column("PREVENTNATPHASE")]
        public bool? PreventNationalPhase { get; set; }

        [Column("FULLMEMBERDATE")]
        public DateTime? FullMembershipDate { get; set; }

        [Column("ASSOCIATEMEMBERDATE")]
        public DateTime? AssociateMemberDate { get; set; }

        [ForeignKey("Id")]
        public Country GroupCountry { get; protected set; }

        [ForeignKey("MemberCountry")]
        public Country GroupMember { get; set; }
    }
}