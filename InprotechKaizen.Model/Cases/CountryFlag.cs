using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
    [Table("COUNTRYFLAGS")]
    public class CountryFlag
    {
        [Obsolete("For persistence only.")]
        public CountryFlag()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "flag")]
        public CountryFlag(string countryCode, int flagNumber, string flagName)
        {
            if (countryCode == null) throw new ArgumentNullException("countryCode");
            if (flagNumber <= 0) throw new ArgumentOutOfRangeException("flagNumber");
            CountryId = countryCode;
            FlagNumber = flagNumber;
            Name = flagName;
        }

        [Key]
        [Column("COUNTRYCODE", Order = 0)]
        [MaxLength(3)]
        public string CountryId { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Key]
        [Column("FLAGNUMBER", Order = 1)]
        public int FlagNumber { get; set; }

        [MaxLength(30)]
        [Column("FLAGNAME")]
        public string Name { get; set; }

        [Column("NATIONALALLOWED")]
        public decimal? AllowNationalPhase { get; set; }

        [Column("RESTRICTREMOVALFLG")]
        public decimal? RestrictRemoval { get; set; }

        [Column("STATUS")]
        public decimal Status { get; set; }

        [MaxLength(50)]
        [Column("PROFILENAME")]
        public string ProfileName { get; set; }

        [Column("FLAGNAME_TID")]
        public int? NameTId { get; set; }

        public bool IsNationalPhaseAllowed => AllowNationalPhase.GetValueOrDefault() == 1;

        public bool IsRemovalRestricted => RestrictRemoval.GetValueOrDefault() == 1;

        public string RegistrationStatus => ((KnownRegistrationStatus) Status).ToString();
    }

    public enum KnownRegistrationStatus
    {
        Dead = 0,
        Pending = 1,
        Registered = 2
    }
}