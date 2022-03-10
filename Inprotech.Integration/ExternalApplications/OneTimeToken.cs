using System;
using System.ComponentModel.DataAnnotations;

namespace Inprotech.Integration.ExternalApplications
{
    public class OneTimeToken
    {
        [Key]
        public long Id { get; set; }

        [Required]
        public string ExternalApplicationName { get; set; }

        [Required]
        public Guid Token { get; set; }

        public DateTime? ExpiryDate { get; set; }
        
        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public int CreatedBy { get; set; }
    }
}