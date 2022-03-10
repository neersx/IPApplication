using System;
using System.ComponentModel.DataAnnotations;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Uspto.PrivatePair.Sponsorships
{
    public class Sponsorship : ISoftDeleteable
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Sponsorship()
        {
        }

        public int Id { get; set; }

        [Required]
        public string SponsorName { get; set; }

        [Required]
        public string SponsoredAccount { get; set; }

        public string CustomerNumbers { get; set; }

        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public int CreatedBy { get; set; }

        public bool IsDeleted { get; set; }

        public DateTime? DeletedOn { get; set; }

        public int? DeletedBy { get; set; }

        public string ServiceId { get; set; }

        public SponsorshipStatus Status { get; set; }

        public DateTime StatusDate { get; set; }

        public string StatusMessage { get; set; }

    }

    public enum SponsorshipStatus : short
    {
        Submitted,
        Active,
        Error
    }
}